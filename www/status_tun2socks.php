<?php
// status_tun2socks.php
header('Content-Type: application/json');

// 检查tun2socks进程是否存在
exec("pgrep -x tun2socks", $output, $return_var);

if ($return_var === 0) {
    echo json_encode(['status' => 'running']);
} else {
    echo json_encode(['status' => 'stopped']);
}
?>