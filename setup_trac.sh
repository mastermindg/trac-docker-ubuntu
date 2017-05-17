#!/usr/bin/env bash

setup_apache() {
    sed -i '128s_.*_ErrorLog /dev/stderr_' /etc/apache2/apache2.conf
    sed -i '129s_.*_TransferLog /dev/stdout_' /etc/apache2/apache2.conf
    if [ ! -f /etc/apache2/sites-enabled/000-default.conf ]; then
	echo -e "<VirtualHost *:80>\n\tServerName trac.local\n\tDocumentRoot $TRAC_DIR/htdocs/\n\tWSGIScriptAlias / $TRAC_DIR/cgi-bin/trac.wsgi\n\n\t<Directory $TRAC_DIR/cgi-bin>\n\t\tWSGIApplicationGroup %{GLOBAL}\n\t\t<IfModule mod_authz_core.c>\n\t\t\tRequire all granted\n\t\t</IfModule>\n\t</Directory>\n</VirtualHost>" > /etc/apache2/sites-enabled/000-default.conf
    fi
}

setup_components() {
    trac-admin $TRAC_DIR config set components tracopt.versioncontrol.git.* enabled
    trac-admin $TRAC_DIR config set components trac.web.auth.LoginModule disabled
    trac-admin $TRAC_DIR config set components acct_mgr.adauth enabled
    trac-admin $TRAC_DIR config set components acct_mgr.web_ui.* enabled
    trac-admin $TRAC_DIR config set components acct_mgr.admin.* enabled
    trac-admin $TRAC_DIR config set components acct_mgr.register.* enabled
    trac-admin $TRAC_DIR config set components acct_mgr.notification.* enabled
    trac-admin $TRAC_DIR config set components acct_mgr.http.HttpAuthStore enabled	
    trac-admin $TRAC_DIR config set components trac.web.auth.loginmodule disabled
    trac-admin $TRAC_DIR config set components acct_mgr.htfile.* disabled
    trac-admin $TRAC_DIR config set components acct_mgr.web_ui.LoginModule enabled
    trac-admin $TRAC_DIR config set components trac.web.auth.LoginModule disabled
}

setup_accountmanager() {
    trac-admin $TRAC_DIR config set account-manager authentication_url "/authFile"
    trac-admin $TRAC_DIR config set account-manager password_store HttpAuthStore
    trac-admin $TRAC_DIR config set account-manager verify_email false
}

# admin username and admin password are the function arguments
setup_admin_user() {
    trac-admin /trac session add admin $TRAC_ADMIN_NAME root@localhost
    trac-admin /trac permission add $TRAC_ADMIN_NAME TRAC_ADMIN
    htpasswd -b -c /trac/.htpasswd $TRAC_ADMIN_NAME $TRAC_ADMIN_PASS
    echo -e "\tUser Setup...$TRAC_ADMIN_NAME $TRAC_ADMIN_PASS"
}

setup_trac() {
    [ ! -d /trac ] && mkdir /trac
    if [ ! -f /trac/VERSION ]; then
	echo -e "\tTrac is not installed...so installing!"
	ls -altr /trac/VERSION
	trac-admin $TRAC_DIR initenv $TRAC_PROJECT_NAME $DB_LINK
	trac-admin $TRAC_DIR deploy /tmp/trac > /dev/null 2>&1
	echo "Trac Apache Deploy..."
        if [ $? -eq 0 ]; then
                echo -e "\tProject deployed successfully"
        else
                echo -e "\tProject deploy failed"
                exit
        fi
        cp -r /tmp/trac/* $TRAC_DIR
        echo "Done deploying for Apache"
        setup_components
	echo "Setup Account Manager"
        setup_accountmanager
	echo "Create user"
	setup_admin_user
	trac-admin /trac config set logging log_type stderr
        [ -f /var/www/trac_logo.png ] && cp -v /var/www/trac_logo.png /trac/htdocs/your_project_logo.png
	chown -R www-data:www-data $TRAC_DIR
    else
	echo -e "\tTrac is already installed so not going to do anything"
    fi
}

echo "Setup trac"
setup_trac
echo "Setup apache"
setup_apache
