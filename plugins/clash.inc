<?php

/*
 * Copyright (C) 2024  https://pfchina.org/
 * All rights reserved.
 *
 */

function clash_services()
{
    global $config;

    $services = array();

        $services[] = array(
            'description' => gettext('Clash'),
            'configd' => array(
                'restart' => array('clash restart'),
                'start' => array('clash start'),
                'stop' => array('clash stop'),
            ),
            'name' => 'clash',
            'pidfile' => '/var/run/clash.pid',
        );
    

    return $services;
}
function clash_syslog()
{
    $logfacilities = array();
    $logfacilities['clash'] = array(
        'facility' => array('clash'),
    );
    return $logfacilities;
}