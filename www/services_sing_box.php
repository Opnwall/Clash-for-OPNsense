<?php
require_once("guiconfig.inc");
include("head.inc");
include("fbegin.inc");

// 配置文件路径
$config_file = "/usr/local/etc/sing-box/config.json";
$log_file = "/var/log/sing-box.log";

// 初始化消息变量
$message = "";

// 执行命令的通用函数
function execCommand($command) {
    exec($command, $output, $return_var);
    return [$output, $return_var];
}

// 获取开机自启状态
function getAutostartStatus() {
    return trim(shell_exec("sysrc -n singbox_enable")) === "YES" ? "YES" : "NO";
}

// 设置开机自启状态
function setAutostartStatus($status) {
    if (!in_array($status, ["YES", "NO"])) {
        return "无效的操作！";
    }
    list($output, $return_var) = execCommand("sysrc singbox_enable=" . escapeshellarg($status));
    return $return_var === 0 ? "开机自启已切换为：$status" : "切换失败！";
}

// 处理服务操作
function handleServiceAction($action) {
    $allowedActions = ['start', 'stop', 'restart'];
    if (!in_array($action, $allowedActions)) {
        return "无效的操作！";
    }
    
    // 重启时清空日志
    if (in_array($action, ['restart'])) {
        file_put_contents("/var/log/sing-box.log", "");
    }

    list($output, $return_var) = execCommand("service singbox " . escapeshellarg($action));

    $messages = [
        'start' => ["sing-box服务启动成功！", "sing-box服务启动失败！"],
        'stop' => ["sing-box服务已停止！", "sing-box服务停止失败！"],
        'restart' => ["sing-box服务重启成功！", "sing-box服务重启失败！"]
    ];
    return $return_var === 0 ? $messages[$action][0] : $messages[$action][1];
}

// 保存配置文件
function saveConfig($file, $content) {
    if (!is_writable($file)) {
        return "配置保存失败，请确保文件可写。";
    }

    if (empty(trim($content))) {
        return "配置内容不能为空！";
    }

    return file_put_contents($file, $content) !== false ? "配置保存成功！" : "配置保存失败！";
}

// 处理表单提交
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = filter_input(INPUT_POST, 'action', FILTER_SANITIZE_STRING);

    switch ($action) {
        case 'save_config':
            $config_content = filter_input(INPUT_POST, 'config_content', FILTER_UNSAFE_RAW);
            $message = saveConfig($config_file, $config_content);
            break;
        case 'toggle_autostart':
            $newStatus = getAutostartStatus() === "YES" ? "NO" : "YES";
            $message = setAutostartStatus($newStatus);
            break;
        default:
            $message = handleServiceAction($action);
    }
}

// 读取配置文件内容
$config_content = file_exists($config_file) ? htmlspecialchars(file_get_contents($config_file)) : "配置文件未找到！";

// 获取开机自启状态
$autostart_status = getAutostartStatus();
?>

<!-- 页面表单显示 -->
<div>
    <?php if (!empty($message)): ?>
    <div class="alert alert-info">
        <?= htmlspecialchars($message); ?>
    </div>
    <?php endif; ?>
</div>
<section class="page-content-main">
    <div class="container-fluid">
        <div class="row">
            <!-- 状态显示 -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>
                                    <strong>服务状态</strong>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <form id="sing-box-status" class="alert alert-secondary">
                                        <i class="fa fa-circle-notch fa-spin"></i> 检查中...
                                    </form>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
            <!-- 服务控制 -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>
                                    <strong>服务控制</strong>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <form method="post" class="form-inline">
                                        <button type="submit" name="action" value="start" class="btn btn-success">
                                            <i class="fa fa-play"></i> 启动
                                        </button>
                                        <button type="submit" name="action" value="stop" class="btn btn-danger">
                                            <i class="fa fa-stop"></i> 停止
                                        </button>
                                        <button type="submit" name="action" value="restart" class="btn btn-warning">
                                            <i class="fa fa-refresh"></i> 重启
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
            <!-- 开机自启 -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>
                                    <strong>开机自启</strong>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <form id="autostart-status" class="alert <?= $autostart_status === 'YES' ? 'alert-success' : 'alert-danger' ?>">
                                        <i class="fa <?= $autostart_status === 'YES' ? 'fa-check-circle' : 'fa-times-circle' ?>"></i>
                                        <?= $autostart_status === 'YES' ? '已启用' : '未启用' ?>
                                    </form>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <form method="post">
                                        <button type="submit" name="action" value="toggle_autostart" class="btn btn-danger">
                                            <i class="fa fa-toggle-on"></i> 切换开关
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
            <!-- 配置管理 -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>
                                    <strong>配置管理</strong>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <form method="post">
                                        <textarea style="max-width:none" name="config_content" rows="10"
                                            class="form-control"><?= $config_content; ?></textarea>
                                        <br>
                                        <button type="submit" name="action" value="save_config" class="btn btn-danger">
                                            <i class="fa fa-save"></i> 保存配置
                                        </button>
                                    </form>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
            <!-- 日志查看 -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td>
                                    <strong>日志查看</strong>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <form method="post">
                                        <textarea style="max-width:none" id="log-viewer" rows="10" class="form-control" readonly></textarea>
                                    </form>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>
        </div>
    </div>
</section>

<script>
// 检查服务状态
function checkSingBoxStatus() {
    fetch('/status_sing_box.php', { cache: 'no-store' })
        .then(response => response.json())
        .then(data => {
            const statusElement = document.getElementById('sing-box-status');
            if (data.status === "running") {
                statusElement.innerHTML = '<i class="fa fa-check-circle text-success"></i> sing-box正在运行';
                statusElement.className = "alert alert-success";
            } else {
                statusElement.innerHTML = '<i class="fa fa-times-circle text-danger"></i> sing-box已停止';
                statusElement.className = "alert alert-danger";
            }
        })
        .catch(error => {
            console.error("状态检查失败:", error.message);
            const statusElement = document.getElementById('sing-box-status');
            statusElement.innerHTML = '<i class="fa fa-times-circle text-danger"></i> 状态检查失败';
            statusElement.className = "alert alert-danger";
        });
}

// 刷新日志
function refreshLogs() {
    fetch('/status_sing_box_logs.php', { cache: 'no-store' })
        .then(response => response.text())
        .then(logContent => {
            const logViewer = document.getElementById('log-viewer');
            logViewer.value = logContent;
            logViewer.scrollTop = logViewer.scrollHeight;
        })
        .catch(error => {
            console.error("日志刷新失败:", error.message);
            const logViewer = document.getElementById('log-viewer');
            logViewer.value += "\n[错误] 无法加载日志，请检查网络或服务器状态。\n";
            logViewer.scrollTop = logViewer.scrollHeight;
        });
}

// 初始化
document.addEventListener('DOMContentLoaded', () => {
    checkSingBoxStatus();
    refreshLogs();
    setInterval(checkSingBoxStatus, 2000);
    setInterval(refreshLogs, 2000);
});
</script>

<?php include("foot.inc"); ?>
