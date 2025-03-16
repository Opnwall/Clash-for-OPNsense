<?php
$log_file = "/var/log/sing-box.log";
$max_lines = 5000;
$display_lines = 200; // 前端仅显示最近 200 行

if (file_exists($log_file)) {
    // 读取日志文件的所有内容
    $log_content = file($log_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);

    // 检查是否超过最大行数
    if (count($log_content) > $max_lines) {
        // 只保留最后 5000 行
        $log_content = array_slice($log_content, -$max_lines);
        file_put_contents($log_file, implode("\n", $log_content) . "\n");
    }

    // 取最近 200 行给前端展示
    $display_content = array_slice($log_content, -$display_lines);

    // 输出日志内容
    echo implode("\n", $display_content);
} else {
    echo "[错误] 日志文件未找到！";
}
?>