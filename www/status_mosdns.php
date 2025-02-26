<?php
header('Content-Type: application/json');

$service_status = [];
exec("service mosdns status", $output, $return_var);

if ($return_var === 0) {
    $service_status['status'] = "running";
} else {
    $service_status['status'] = "stopped";
}

echo json_encode($service_status);
?>
