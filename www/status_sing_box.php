<?php
// status_sing_box.php
header('Content-Type: application/json');

// 检查sing-box进程是否存在
exec("pgrep -x sing-box", $output, $return_var);

if ($return_var === 0) {
    echo json_encode(['status' => 'running']);
} else {
    echo json_encode(['status' => 'stopped']);
}
?>