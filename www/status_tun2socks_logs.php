<?php
$log_file = "/var/log/tun2socks.log";

if (file_exists($log_file)) {
    echo htmlspecialchars(file_get_contents($log_file));
} else {
    echo "[日志文件未找到]";
}