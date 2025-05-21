<?php
// status_clash.php
header('Content-Type: application/json');

// 检查clash进程是否存在
exec("pgrep -x clash", $output, $return_var);

if ($return_var === 0) {
    echo json_encode(['status' => 'running']);
} else {
    echo json_encode(['status' => 'stopped']);
}
?>