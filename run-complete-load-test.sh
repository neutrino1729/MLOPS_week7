#!/bin/bash

EXTERNAL_IP=35.238.193.245

# Create wrk script
cat > post-predict.lua << 'EOF'
wrk.method = "POST"
wrk.body = '{"sepal_length": 5.1, "sepal_width": 3.5, "petal_length": 1.4, "petal_width": 0.2}'
wrk.headers["Content-Type"] = "application/json"
EOF

echo "======================================================"
echo "IRIS CLASSIFIER - COMPREHENSIVE LOAD TEST"
echo "======================================================"

# Phase 1
echo -e "\n[Phase 1] Baseline: 10 connections, 30s"
wrk -t2 -c10 -d30s -s post-predict.lua http://$EXTERNAL_IP/predict/
sleep 15
kubectl get hpa -n iris-classifier

# Phase 2
echo -e "\n[Phase 2] Medium Load: 100 connections, 60s"
wrk -t4 -c100 -d60s -s post-predict.lua http://$EXTERNAL_IP/predict/
sleep 20
kubectl get pods -n iris-classifier | grep iris-api
kubectl get hpa -n iris-classifier

# Phase 3
echo -e "\n[Phase 3] Heavy Load: 500 connections, 90s"
wrk -t8 -c500 -d90s -s post-predict.lua http://$EXTERNAL_IP/predict/
sleep 30
kubectl get pods -n iris-classifier -o wide | grep iris-api
kubectl get hpa -n iris-classifier

# Phase 4
echo -e "\n[Phase 4] Single Pod: 1000 connections, 30s"
kubectl scale deployment/iris-api --replicas=1 -n iris-classifier
sleep 60
wrk -t8 -c1000 -d30s -s post-predict.lua http://$EXTERNAL_IP/predict/
kubectl get hpa -n iris-classifier

# Phase 5
echo -e "\n[Phase 5] Extreme Load: 2000 connections, 60s"
wrk -t12 -c2000 -d60s -s post-predict.lua http://$EXTERNAL_IP/predict/
sleep 30

echo -e "\n======================================================"
echo "FINAL RESULTS"
echo "======================================================"
kubectl get pods -n iris-classifier
kubectl get hpa -n iris-classifier
kubectl top pods -n iris-classifier 2>/dev/null || echo "Metrics not available"

# Generate report
REPORT="load-test-report-$(date +%Y%m%d-%H%M%S).txt"
{
  echo "=== LOAD TEST REPORT ==="
  echo "Date: $(date)"
  echo ""
  kubectl get pods -n iris-classifier -o wide
  echo ""
  kubectl get hpa -n iris-classifier
  echo ""
  kubectl describe hpa iris-api-hpa -n iris-classifier
} > $REPORT

echo -e "\n✅ Report saved: $REPORT"
