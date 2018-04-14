#!/bin/bash
# Copyright (c) 2000-2016 Synology Inc. All rights reserved.

PKG_NAME="Gitea"
BACKUP_CONFIG="/usr/syno/etc/packages/__PKG_NAME__/config"

NeedRestore()
{
	if [ -f "$BACKUP_CONFIG" ]; then
		return 0
	else
		return 1
	fi
}

GetDBName()
{
	get_key_value "$BACKUP_CONFIG" DB_NAME
}

GetDBUser()
{
	#version < "9.4.4-0050" does not store db_user in config
	DB_USER=$(get_key_value "$BACKUP_CONFIG" DB_USER)
	DB_USER=${DB_USER:-gitea_user}
	echo "$DB_USER"
}

GetDBPass()
{
	get_key_value "$BACKUP_CONFIG" DB_PASS
}

GetShare()
{
	get_key_value "$BACKUP_CONFIG" SHARE
}

GetPkgVer()
{
	get_key_value "$BACKUP_CONFIG" PKG_VER
}
wizard_db_settings="Set up Gitea Database"
wizard_db_name_desc="Please enter the database name for Gitea."
wizard_db_name_label="Database name"
wizard_admin_acc="Account"
wizard_admin_pass="Password"
wizard_set_db_desc="Please create a new exclusive database account for Gitea to use existing/new data."
wizard_set_data_title="Set up Gitea"
wizard_found_backup="Please select a method to import data."
wizard_decide_restore="Gitea database already exists.<br>Please select either of the following actions:"
wizard_restore="Use existing data"
wizard_create_new="Clean install (All existing data, including configuration files and the database, will be removed.)"
wizard_db_root_password_desc="Please enter new database root password."
wizard_db_root_password_label="Database root password"
wizard_db_user_account_desc="Database user account"
wizard_db_user_password_desc="Database user password"
install_title="Install Gitea"
install_data_root_desc="Create a shared folder to store the data of Gitea."
install_data_root_label="Shared folder name"
http_port_desc="Please enter the external HTTP port number for Gitea."
http_port_label="HTTP port number"
http_container_port_desc="Please select the internal Gitea Container Port."
http_container_port_label="HTTP Connection"
ssh_port_desc="Please enter the external SSH port number for Gitea."
ssh_port_label="SSH port number"
hostname_label="Domain name"

PageRestore()
{
cat << EOF
{
	"step_title": "$wizard_found_backup",
	"items": [{
		"type": "singleselect",
		"desc": "$wizard_decide_restore",
		"subitems": [{
			"key": "restore_backup",
			"desc": "$wizard_restore",
			"defaultValue": true
		}, {
			"desc": "$wizard_create_new",
			"defaultValue": false
		}]
	}, {
		"type": "textfield",
		"subitems": [{
			"key": "worker_mode",
			"desc": "drop or skip",
			"defaultValue": "skip",
			"hidden": true
		}]
	}]
}
EOF
}

CheckRestore()
{
cat << EOF
// find constructor contains restore page
for (i = arguments[0].ownerCt.items.length-1; i >= 1; i--){
	page = arguments[0].ownerCt.items.items[i];
	if (page.headline === \"${wizard_found_backup}\"){
		// check whether user wants to restore or not
		restore = page.items.items[1].checked;
		break;
	}
}
EOF
}

FindObj()
{
cat << EOF
for (i = 0; i < arguments[0].items.length; i++) {
	item = arguments[0].items.items[i]
	if (\"${1}\" === item.itemId){
		$2 = arguments[0].items.items[i];
		break;
	}
}
EOF
}


ApplyDBInfo()
{
	local page_db="$1"

	sed "s/@OLD_DB@/$DB_NAME/g;s/@OLD_USER@/$DB_USER/g;s/@OLD_DATAROOT@/$OLD_DATAROOT/g" <<< "$page_db"
}

PageDB()
{
	local page_db=$(cat << EOF
{
	"step_title": "$wizard_db_settings",
	"items": [{
		"type": "password",
		"desc": "$wizard_db_root_password_desc",
		"subitems": [{
			"key": "pkgwizard_db_root_password",
			"desc": "$wizard_db_root_password_label",
			"indent": 1
		}]
	},{
		"type": "textfield",
		"desc": "$wizard_set_db_desc",
		"subitems": [{
			"key": "pkgwizard_db_name",
			"desc": "$wizard_db_name_label",
			"defaultValue": "gitea"
		}]
	}, {
		"type": "textfield",
		"subitems": [{
			"indent": 1,
			"key": "pkgwizard_db_user_account",
			"desc": "$wizard_db_user_account_desc",
			"defaultValue": "gitea_user"
		}]
	}, {
		"type": "password",
		"subitems": [{
			"indent": 1,
			"key": "pkgwizard_db_user_password",
			"desc": "$wizard_db_user_password_desc"
		}]
	}]
}
EOF
)
	ApplyDBInfo "$page_db"
}
PageInstallSetting()
{
cat << EOF
{
	"step_title": "$install_title",
	"items": [{
		"type": "textfield",
		"desc": "$install_data_root_desc",
		"subitems": [{
			"key": "pkgwizard_dataroot",
			"desc": "$install_data_root_label",
			"defaultValue": "gitea",
			"validator": {
				"allowBlank": false
			}
		}]
	},{
		"type": "textfield",
		"desc": "$http_port_desc",
		"subitems": [{
			"key": "pkgwizard_http_port",
			"desc": "$http_port_label",
			"defaultValue": "3000",
			"validator": {
				"allowBlank": false,
				"regex": {
					"expr": "/^[1-9]\\\\d{0,4}$/"
				},
				"fn": "{var port=arguments[0]; if (port == 80 || port == 443) return 'Ports 80 and 443 are reserved ports and can not be remapped by docker!';return true;}"
			}
		}]
	},{
		"type": "textfield",
		"desc": "$ssh_port_desc",
		"subitems": [{
			"key": "pkgwizard_ssh_port",
			"desc": "$ssh_port_label",
			"defaultValue": "3022",
			"validator": {
				"allowBlank": false,
				"regex": {
					"expr": "/^[1-9]\\\\d{0,4}$/"
				},
				"fn": "{var port=arguments[0]; if (port == 22) return 'Port 22 is a reserved port and can not be remapped by docker!';return true;}"
			}
		}]
	},{
    "type": "combobox",
    "desc": "$http_container_port_desc",
    "subitems": [{
      "key": "pkgwizard_container_port",
      "desc": "$http_container_port_label",
      "defaultValue": "HTTP",
      "displayField": "display_name",
      "editable": false,
      "store": [["HTTP","HTTP (Port 80)"],["HTTPS","HTTPS (Port 443)"],["HTTPS_SELF_SIGNED","HTTPS_SELF_SIGNED (Port 443)"]]
    }]
  }]
},{
	"step_title": "$install_title",
	"items": [{
		"type": "textfield",
		"desc": "$hostname_desc",
		"subitems": [{
			"key": "pkgwizard_hostname",
			"desc": "$hostname_label",
			"defaultValue": "localhost",
			"validator": {
				"allowBlank": false
			}
		}]
	}]
}
EOF
}
main()
{
	local install_page=""

	DEFAULT_RESTORE=false
	DB_NAME="$(GetDBName)"
	DB_USER="$(GetDBUser)"
	OLD_DATAROOT="$(GetShare)"

	if NeedRestore; then
		install_page="$(PageRestore),$(PageInstallSetting),$(PageDB)"
	else
		install_page="$(PageInstallSetting),$(PageDB)"
	fi

	echo "[$install_page]" > "${SYNOPKG_TEMP_LOGFILE}"

	return 0
}

main "$@"

