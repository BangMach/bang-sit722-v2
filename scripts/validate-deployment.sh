#!/bin/bash

# Deployment Validation Script for bang-sit722-v2 Project
# This script validates the deployment and performs health checks

set -e

echo "=========================================="
echo "Deployment Validation for bang-sit722-v2"
echo "=========================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✓ $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}✗ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠ $message${NC}"
            ;;
        "INFO")
            echo -e "ℹ $message"
            ;;
    esac
}

# Function to check if a service is healthy
check_service_health() {
    local service_name=$1
    local service_url=$2
    local max_attempts=${3:-5}
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$service_url/health" > /dev/null 2>&1; then
            print_status "SUCCESS" "$service_name is healthy"
            return 0
        fi
        print_status "WARNING" "$service_name health check attempt $attempt/$max_attempts failed"
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_status "ERROR" "$service_name health check failed after $max_attempts attempts"
    return 1
}

# Function to check Kubernetes deployment status
check_k8s_deployment() {
    local deployment_name=$1
    
    if kubectl get deployment "$deployment_name" &> /dev/null; then
        local ready_replicas=$(kubectl get deployment "$deployment_name" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired_replicas=$(kubectl get deployment "$deployment_name" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        if [ "$ready_replicas" = "$desired_replicas" ] && [ "$ready_replicas" != "0" ]; then
            print_status "SUCCESS" "Deployment $deployment_name is ready ($ready_replicas/$desired_replicas replicas)"
            return 0
        else
            print_status "ERROR" "Deployment $deployment_name is not ready ($ready_replicas/$desired_replicas replicas)"
            return 1
        fi
    else
        print_status "ERROR" "Deployment $deployment_name not found"
        return 1
    fi
}

# Function to get service external IP
get_service_ip() {
    local service_name=$1
    local ip=$(kubectl get svc "$service_name" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ ! -z "$ip" ] && [ "$ip" != "null" ]; then
        echo "$ip"
        return 0
    else
        return 1
    fi
}

# Check prerequisites
print_status "INFO" "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_status "ERROR" "kubectl is not installed or not in PATH"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    print_status "ERROR" "curl is not installed"
    exit 1
fi

# Check kubectl connection
if ! kubectl cluster-info &> /dev/null; then
    print_status "ERROR" "Cannot connect to Kubernetes cluster. Check your kubectl configuration."
    exit 1
fi

print_status "SUCCESS" "kubectl connection verified"

# Get current context
CURRENT_CONTEXT=$(kubectl config current-context)
print_status "INFO" "Current Kubernetes context: $CURRENT_CONTEXT"

echo ""
echo "Checking Kubernetes Deployments..."
echo "=================================="

# Check database deployments
check_k8s_deployment "product-db" || DEPLOYMENT_ISSUES=true
check_k8s_deployment "order-db" || DEPLOYMENT_ISSUES=true
check_k8s_deployment "customer-db" || DEPLOYMENT_ISSUES=true
check_k8s_deployment "rabbitmq" || DEPLOYMENT_ISSUES=true

# Check application deployments
check_k8s_deployment "product-service" || DEPLOYMENT_ISSUES=true
check_k8s_deployment "order-service" || DEPLOYMENT_ISSUES=true
check_k8s_deployment "customer-service" || DEPLOYMENT_ISSUES=true
check_k8s_deployment "frontend" || DEPLOYMENT_ISSUES=true

echo ""
echo "Checking Service LoadBalancer IPs..."
echo "===================================="

# Get service IPs
PRODUCT_IP=$(get_service_ip "product-service-w05-aks") || PRODUCT_IP=""
ORDER_IP=$(get_service_ip "order-service-w05-aks") || ORDER_IP=""
CUSTOMER_IP=$(get_service_ip "customer-service-w05-aks") || CUSTOMER_IP=""
FRONTEND_IP=$(get_service_ip "frontend-service") || FRONTEND_IP=""

if [ ! -z "$PRODUCT_IP" ]; then
    print_status "SUCCESS" "Product Service IP: $PRODUCT_IP"
else
    print_status "WARNING" "Product Service IP not available"
fi

if [ ! -z "$ORDER_IP" ]; then
    print_status "SUCCESS" "Order Service IP: $ORDER_IP"
else
    print_status "WARNING" "Order Service IP not available"
fi

if [ ! -z "$CUSTOMER_IP" ]; then
    print_status "SUCCESS" "Customer Service IP: $CUSTOMER_IP"
else
    print_status "WARNING" "Customer Service IP not available"
fi

if [ ! -z "$FRONTEND_IP" ]; then
    print_status "SUCCESS" "Frontend IP: $FRONTEND_IP"
else
    print_status "WARNING" "Frontend IP not available"
fi

echo ""
echo "Performing Health Checks..."
echo "==========================="

HEALTH_CHECK_FAILED=false

# Check service health if IPs are available
if [ ! -z "$PRODUCT_IP" ]; then
    check_service_health "Product Service" "http://$PRODUCT_IP:8000" || HEALTH_CHECK_FAILED=true
else
    print_status "WARNING" "Skipping Product Service health check (no IP)"
fi

if [ ! -z "$ORDER_IP" ]; then
    check_service_health "Order Service" "http://$ORDER_IP:8001" || HEALTH_CHECK_FAILED=true
else
    print_status "WARNING" "Skipping Order Service health check (no IP)"
fi

if [ ! -z "$CUSTOMER_IP" ]; then
    check_service_health "Customer Service" "http://$CUSTOMER_IP:8002" || HEALTH_CHECK_FAILED=true
else
    print_status "WARNING" "Skipping Customer Service health check (no IP)"
fi

echo ""
echo "Checking Pod Status..."
echo "====================="

# Check for any pods in error state
ERROR_PODS=$(kubectl get pods --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)
if [ "$ERROR_PODS" -gt 0 ]; then
    print_status "ERROR" "$ERROR_PODS pods are not running"
    echo "Problematic pods:"
    kubectl get pods --field-selector=status.phase!=Running,status.phase!=Succeeded
    DEPLOYMENT_ISSUES=true
else
    print_status "SUCCESS" "All pods are running successfully"
fi

echo ""
echo "Checking Resource Usage..."
echo "========================="

# Check node resource usage
kubectl top nodes 2>/dev/null && print_status "SUCCESS" "Node resource usage retrieved" || print_status "WARNING" "Cannot retrieve node resource usage (metrics server may not be installed)"

# Check pod resource usage
kubectl top pods 2>/dev/null && print_status "SUCCESS" "Pod resource usage retrieved" || print_status "WARNING" "Cannot retrieve pod resource usage (metrics server may not be installed)"

echo ""
echo "=========================================="
echo "Deployment Validation Summary"
echo "=========================================="

if [ "$DEPLOYMENT_ISSUES" = true ] || [ "$HEALTH_CHECK_FAILED" = true ]; then
    print_status "ERROR" "Deployment validation failed. Please check the issues above."
    
    echo ""
    echo "Troubleshooting commands:"
    echo "- Check pod logs: kubectl logs <pod-name>"
    echo "- Describe problematic pods: kubectl describe pod <pod-name>"
    echo "- Check events: kubectl get events --sort-by=.metadata.creationTimestamp"
    echo "- Check service endpoints: kubectl get endpoints"
    
    exit 1
else
    print_status "SUCCESS" "All deployment validation checks passed!"
    
    echo ""
    echo "Application URLs:"
    [ ! -z "$PRODUCT_IP" ] && echo "- Product Service: http://$PRODUCT_IP:8000"
    [ ! -z "$ORDER_IP" ] && echo "- Order Service: http://$ORDER_IP:8001"
    [ ! -z "$CUSTOMER_IP" ] && echo "- Customer Service: http://$CUSTOMER_IP:8002"
    [ ! -z "$FRONTEND_IP" ] && echo "- Frontend: http://$FRONTEND_IP"
    
    echo ""
    echo "API Documentation:"
    [ ! -z "$PRODUCT_IP" ] && echo "- Product Service API: http://$PRODUCT_IP:8000/docs"
    [ ! -z "$ORDER_IP" ] && echo "- Order Service API: http://$ORDER_IP:8001/docs"
    [ ! -z "$CUSTOMER_IP" ] && echo "- Customer Service API: http://$CUSTOMER_IP:8002/docs"
    
    echo ""
    print_status "SUCCESS" "Deployment is healthy and ready for use!"
fi