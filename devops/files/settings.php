<?php

/**
 * Database settings:
 *
 * @code
 * $databases['default']['default'] = [
 *   'database' => 'databasename',
 *   'username' => 'sqlusername',
 *   'password' => 'sqlpassword',
 *   'host' => 'localhost',
 *   'port' => '3306',
 *   'driver' => 'mysql',
 *   'prefix' => '',
 *   'collation' => 'utf8mb4_general_ci',
 * ];
 * @endcode
 */
$databases = [];
$databases['default']['default'] = [
  'database' => 'rhgithubdb',
  'username' => 'root',
  'password' => 'TerriblePassword',
  'host' => getenv('DB_HOST'),
  'port' => '3306',
  'driver' => 'mysql',
  'prefix' => '',
  'collation' => 'utf8mb4_general_ci',
];

$settings['hash_salt'] = 'saltyyyydog';

$settings['update_free_access'] = FALSE;

$settings['container_yamls'][] = $app_root . '/' . $site_path . '/services.yml';

$settings['file_scan_ignore_directories'] = [
  'node_modules',
  'bower_components',
];

$settings['entity_update_batch_size'] = 50;

$settings['entity_update_backup'] = TRUE;

$settings['migrate_node_migrate_type_classic'] = FALSE;

$settings['trusted_host_patterns'] = array(
  '^philsgitemporium\.com$',
  '^.+\.philsgitemporium\.com$',
);

$settings['file_private_path'] = '/mnt/web/private';
$settings['config_sync_directory'] = '/mnt/web/private/sync';
