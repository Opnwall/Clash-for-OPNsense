<?php
require_once("guiconfig.inc");
include("head.inc");
include("fbegin.inc");

define('ENV_FILE', '/usr/local/etc/clash/sub/env');
define('LOG_FILE', '/var/log/sub.log');

function log_message($message, $log_file = LOG_FILE) {
    $time = date("Y-m-d H:i:s");
    $log_entry = "[{$time}] {$message}\n";
    try {
        file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
    } catch (Exception $e) {
        error_log("日志写入失败: " . $e->getMessage());
    }
}

function clear_log($log_file = LOG_FILE) {
    try {
        file_put_contents($log_file, '', LOCK_EX);
    } catch (Exception $e) {
        error_log("日志清空失败: " . $e->getMessage());
    }
}

function save_env_variable($key, $value, $env_file = ENV_FILE) {
    if (empty($key) || empty($value)) return false;

    $lines = file_exists($env_file) ? file($env_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) : [];
    $new_lines = [];

    foreach ($lines as $line) {
        if (!preg_match("/^export {$key}=.*$/", $line)) {
            $new_lines[] = $line;
        }
    }

    $new_lines[] = "export {$key}='{$value}'";
    try {
        file_put_contents($env_file, implode("\n", $new_lines) . "\n", LOCK_EX);
        return true;
    } catch (Exception $e) {
        error_log("环境变量保存失败: " . $e->getMessage());
        return false;
    }
}

function load_env_variables($env_file = ENV_FILE) {
    $env_vars = [];
    if (file_exists($env_file)) {
        $env_lines = file($env_file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($env_lines as $line) {
            if (preg_match('/^export (\w+)=\'?(.*?)\'?$/', $line, $matches)) {
                $env_vars[$matches[1]] = $matches[2];
            }
        }
    }
    return $env_vars;
}

$message = '';

function handle_form_submission() {
    global $message;

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (isset($_POST['save'])) {
            $url = filter_input(INPUT_POST, 'subscribe_url', FILTER_SANITIZE_URL);
            $secret = filter_input(INPUT_POST, 'clash_secret', FILTER_SANITIZE_STRING);

            clear_log();

            $url_saved = save_env_variable('CLASH_URL', $url);
            $secret_saved = save_env_variable('CLASH_SECRET', $secret);

            if ($url_saved) {
                log_message("订阅地址已保存：{$url}");
            } else {
                $message .= "<div class='alert alert-danger'>保存订阅地址失败！</div>";
            }

            if ($secret_saved) {
                log_message("安全密钥已保存。");
            } else {
                $message .= "<div class='alert alert-danger'>保存安全密钥失败！</div>";
            }

            if (!$message) {
                $message = "<div class='alert alert-success'>设置已成功保存。</div>";
            }
        }

        if (isset($_POST['action']) && $_POST['action'] === '立即订阅') {
            clear_log();
            $cmd = escapeshellcmd("bash /usr/local/etc/clash/sub/sub.sh");
            exec($cmd . " >> " . LOG_FILE . " 2>&1", $output_lines, $return_var);
            log_message("订阅操作执行完毕。");
            $message = "<div class='alert alert-info'>订阅操作已执行。</div>";
        }
    }
}

$env_vars = load_env_variables();
$current_url = $env_vars['CLASH_URL'] ?? '';
$current_secret = $env_vars['CLASH_SECRET'] ?? '';

handle_form_submission();
$env_vars = load_env_variables();
$current_url = $env_vars['CLASH_URL'] ?? '';
$current_secret = $env_vars['CLASH_SECRET'] ?? '';

$log_lines = file_exists(LOG_FILE) ? file(LOG_FILE) : [];
$log_tail = array_slice($log_lines, -100);
$log_content = htmlspecialchars(implode("", $log_tail));
?>

<!-- 页面表单 -->
<section class="page-content-main">
    <div class="container-fluid">
        <div class="row">
            <!-- 提示信息 -->
            <?php if (!empty($message)): ?>
                <div class="col-xs-12">
                    <?= $message ?>
                </div>
            <?php endif; ?>

            <!-- 订阅管理 -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr><td><strong>Clash 订阅管理</strong></td></tr>
                            <tr>
                                <td>
                                    <form method="post" class="form-group">
                                        <label for="subscribe_url">订阅地址：</label>
                                        <input type="text" id="subscribe_url" name="subscribe_url" value="<?= htmlspecialchars($current_url); ?>" class="form-control" placeholder="输入订阅地址" autocomplete="off" />
                                        <label for="clash_secret">访问密钥：</label>
                                        <input type="text" id="clash_secret" name="clash_secret" value="<?= htmlspecialchars($current_secret); ?>" class="form-control" placeholder="输入安全密钥" autocomplete="off" />
                                        <br>
                                        <button type="submit" name="save" class="btn btn-danger"><i class="fa fa-save"></i> 保存设置</button>
                                        <button type="submit" name="action" value="立即订阅" class="btn btn-success"><i class="fa fa-sync"></i> 开始订阅</button>
                                    </form>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </section>

            <!-- 实时日志显示 -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr><td><strong>日志查看</strong></td></tr>
                            <tr>
                                <td>
                                    <form class="form-group">
                                        <textarea readonly style="max-width:none" name="log_content" rows="20" class="form-control"><?= $log_content; ?></textarea>
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

<?php include("foot.inc"); ?>