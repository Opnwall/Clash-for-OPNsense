<?php
require_once("guiconfig.inc");
include("head.inc");
include("fbegin.inc");

// 配置文件路径
$config_file = "/usr/local/etc/clash/config.yaml";
$log_file = "/var/log/clash.log";

// 消息变量初始化
$message = "";

// 服务控制函数
function handleServiceAction($action)
{
    $allowedActions = ['start', 'stop', 'restart'];
    if (!in_array($action, $allowedActions)) {
        return "无效的操作！";
    }
    // 清空日志文件（仅在启动或重启时）
    if ($action === 'start' || $action === 'restart') {
        file_put_contents("/var/log/clash.log", ""); // 清空日志文件
    }
    // 执行服务操作
    $command = escapeshellcmd("service clash $action");
    exec($command, $output, $return_var);

    $messages = [
        'start' => ["Clash服务启动成功！", "Clash服务启动失败！"],
        'stop' => ["Clash服务已停止！", "Clash服务停止失败！"],
        'restart' => ["Clash服务重启成功！", "Clash服务重启失败！"]
    ];

    return $return_var === 0 ? $messages[$action][0] : $messages[$action][1];
}

// 配置保存函数
function saveConfig($file, $content)
{
    if (!is_writable($file)) {
        return "配置保存失败，请确保文件可写。";
    }

    try {
        if (empty($content)) {
            return "配置内容不能为空！";
        }

        if (file_put_contents($file, $content) !== false) {
            return "配置保存成功！";
        }
    } catch (Exception $e) {
        return "配置保存失败: " . $e->getMessage();
    }

    return "配置保存失败！";
}

// 表单提交处理
if ($_POST) {
    $action = $_POST['action'] ?? '';
    if ($action === 'save_config') {
        $config_content = $_POST['config_content'] ?? '';
        $message = saveConfig($config_file, $config_content);
    } else {
        $message = handleServiceAction($action);
    }
}

// 读取配置文件内容
$config_content = file_exists($config_file) ? htmlspecialchars(file_get_contents($config_file)) : "配置文件未找到！";
?>

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
                                    <div id="clash-status" class="alert alert-secondary">
                                        <i class="fa fa-circle-notch fa-spin"></i> 检查中...
                                    </div>
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
function checkClashStatus() {
    fetch('/status_clash.php', { cache: 'no-store' })
        .then(response => response.json())
        .then(data => {
            const statusElement = document.getElementById('clash-status');
            if (data.status === "running") {
                statusElement.innerHTML = '<i class="fa fa-check-circle text-success"></i> Clash正在运行';
                statusElement.className = "alert alert-success";
            } else {
                statusElement.innerHTML = '<i class="fa fa-times-circle text-danger"></i> Clash已停止';
                statusElement.className = "alert alert-danger";
            }
        })
        .catch(error => {
            console.error("状态检查失败:", error.message);
            const statusElement = document.getElementById('clash-status');
            statusElement.innerHTML = '<i class="fa fa-times-circle text-danger"></i> 状态检查失败';
            statusElement.className = "alert alert-danger";
        });
}

// 实时刷新日志
function refreshLogs() {
    fetch('/status_clash_logs.php', { cache: 'no-store' })
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

// 页面加载时初始化
document.addEventListener('DOMContentLoaded', () => {
    checkClashStatus();
    refreshLogs();
    setInterval(checkClashStatus, 3000);
    setInterval(refreshLogs, 2000);
});
</script>

<?php include("foot.inc"); ?>
