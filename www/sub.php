<?php
require_once("guiconfig.inc");
include("head.inc");
include("fbegin.inc");

// 配置文件路径
define('ENV_FILE', '/usr/local/etc/clash/sub/env');
define('LOG_FILE', '/var/log/sub.log');

/**
 * 记录日志
 * @param string $message 日志内容
 * @param string $log_file 日志文件路径
 */
function log_message($message, $log_file = LOG_FILE) {
    $time = date("Y-m-d H:i:s");
    $log_entry = "[{$time}] {$message}\n";
    try {
        file_put_contents($log_file, $log_entry, FILE_APPEND | LOCK_EX);
    } catch (Exception $e) {
        error_log("日志写入失败: " . $e->getMessage());
    }
}

/**
 * 清空日志文件
 * @param string $log_file 日志文件路径
 */
function clear_log($log_file = LOG_FILE) {
    try {
        file_put_contents($log_file, '', LOCK_EX);
    } catch (Exception $e) {
        error_log("日志清空失败: " . $e->getMessage());
    }
}

/**
 * 保存环境变量到文件
 * @param string $key 变量名
 * @param string $value 变量值
 * @param string $env_file 环境文件路径
 * @return bool 是否保存成功
 */
function save_env_variable($key, $value, $env_file = ENV_FILE) {
    if (empty($key) || empty($value)) {
        return false;
    }

    $env_content = "export {$key}='{$value}'\n";
    try {
        file_put_contents($env_file, $env_content, FILE_APPEND | LOCK_EX);
        return true;
    } catch (Exception $e) {
        error_log("环境变量保存失败: " . $e->getMessage());
        return false;
    }
}

/**
 * 加载环境变量
 * @param string $env_file 环境文件路径
 * @return array 包含所有环境变量的数组
 */
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

/**
 * 处理表单提交
 */
function handle_form_submission() {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (isset($_POST['save'])) {
            $url = filter_input(INPUT_POST, 'subscribe_url', FILTER_SANITIZE_STRING);
            $secret = filter_input(INPUT_POST, 'clash_secret', FILTER_SANITIZE_STRING);

            clear_log();

            $url_saved = save_env_variable('CLASH_URL', $url);
            $secret_saved = save_env_variable('CLASH_SECRET', $secret);

            if ($url_saved) {
                log_message("订阅地址已保存：{$url}");
            } else {
                echo "<div class='alert alert-danger'>保存订阅地址失败！</div>";
            }

            if ($secret_saved) {
                log_message("安全密钥已保存。");
            } else {
                echo "<div class='alert alert-danger'>保存安全密钥失败！</div>";
            }

            header("Location: " . $_SERVER['PHP_SELF']);
            exit;
        }

        if (isset($_POST['action']) && $_POST['action'] === '立即订阅') {
            clear_log();
            $cmd = escapeshellcmd("bash /usr/local/etc/clash/sub/sub.sh");
            exec($cmd . " >> " . LOG_FILE . " 2>&1", $output_lines, $return_var);
            $output = implode("\n", $output_lines);
            log_message("订阅操作执行完毕。");
        }
    }
}

// 加载当前订阅地址和密钥
$env_vars = load_env_variables();
$current_url = $env_vars['CLASH_URL'] ?? '';
$current_secret = $env_vars['CLASH_SECRET'] ?? '';

// 处理表单提交
handle_form_submission();

// 读取日志文件内容
$log_content = file_exists(LOG_FILE) ? htmlspecialchars(file_get_contents(LOG_FILE)) : '';
?>

<!-- 页面表单 -->
<section class="page-content-main">
    <div class="container-fluid">
        <div class="row">
            <!-- 订阅管理 -->
            <section class="col-xs-12">
                <div class="content-box tab-content table-responsive __mb">
                    <table class="table table-striped">
                        <tbody>
                            <tr>
                                <td><strong>Clash 订阅管理</strong></td>
                            </tr>
                            <tr>
                                <td>
                                    <form method="post" class="form-group">
                                        <label for="subscribe_url">订阅地址：</label>
                                        <input type="text" id="subscribe_url" name="subscribe_url" value="<?php echo htmlspecialchars($current_url); ?>" class="form-control" placeholder="输入订阅地址" autocomplete="off" />
                                        <label for="clash_secret">访问密钥：</label>
                                        <input type="text" id="clash_secret" name="clash_secret" value="<?php echo htmlspecialchars($current_secret); ?>" class="form-control" placeholder="输入安全密钥" autocomplete="off" />
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
                            <tr>
                                <td><strong>日志查看</strong></td>
                            </tr>
                            <tr>
                                <td>
                                    <form class="form-group">
                                        <textarea style="max-width:none" name="log_content" rows="23" class="form-control"><?php echo $log_content; ?></textarea>
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
<?php
include("foot.inc");
?>