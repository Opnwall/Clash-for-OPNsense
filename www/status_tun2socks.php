<?php
header("Content-Type: application/json");
$status = shell_exec("service tun2socks status");
if (strpos($status, "is running") !== false) {
    echo json_encode(["status" => "running"]);
} else {
    echo json_encode(["status" => "stopped"]);
}