#!/bin/bash

# @TODO
# maria db migration

IS_DEBUG=0

########################################################################################################################
# DEFAULT PARAMETERS
########################################################################################################################
gitea_target_package_fqn="gitea/gitea:1.4"
gitea_target_package_download_size=700

spk_version=0100

########################################################################################################################
# PARAMETER HANDLING
########################################################################################################################
for i in "$@"
do
    case $i in
        -gv=*|--gitea-fqn=*)
            gitea_target_package_fqn="${i#*=}"
        ;;
        -gs=*|--gitea-download-size=*)
            gitea_target_package_download_size="${i#*=}"
        ;;
        -v=*|--spk-version=*)
            spk_version="${i#*=}"
        ;;
        --debug)
            IS_DEBUG=1
        ;;
        *)
            # unknown option
        ;;
    esac
    shift
done

########################################################################################################################
# PROCESS VARIABLES
########################################################################################################################
gitea_target_package_name=$(echo "$gitea_target_package_fqn" | cut -f1 -d:)
gitea_target_package_version=$(echo "$gitea_target_package_fqn" | cut -f2 -d:)
gitea_target_package_name_escaped=$(echo "$gitea_target_package_name" | tr '/' '-')

########################################################################################################################
# VARIABLES
########################################################################################################################
project_name="synology-gitea-jboxberger"
current_dir=$(cd -P -- "$(dirname -- "$0")" && pwd -P)
project_tmp="$current_dir/tmp"
project_src="$current_dir/src"
project_build="$current_dir/build/$gitea_target_package_version"

########################################################################################################################
# INIT
########################################################################################################################
if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ] || \
  [ $(dpkg-query -W -f='${Status}' jq 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    sudo apt-get update
    sudo apt-get install -y git jq python
fi

if [ -d $project_build ]; then
  rm -rf $project_build
fi
mkdir -p $project_build

if [ -d $project_tmp ]; then
  rm -rf $project_tmp
fi
mkdir -p "$project_tmp"

########################################################################################################################
# INITIALIZE BASE PACKAGE
########################################################################################################################
cp -R "$project_src/." "$project_tmp"

########################################################################################################################
# FIX LANG FILE
########################################################################################################################
cd "$project_tmp/scripts/lang"
ln -s enu default
cd "$current_dir"

synology_gitea_config="$project_tmp/package/config/synology_gitea"
synology_gitea_db_config="$project_tmp/package/config/synology_gitea_db"

########################################################################################################################
# MODIFY GITEA VERSION
########################################################################################################################
jq -c --arg image "$gitea_target_package_name:$gitea_target_package_version"  '.image=$image' <$synology_gitea_config >$synology_gitea_config".out" && mv $synology_gitea_config".out" $synology_gitea_config
jq -c '.is_package=false' <$synology_gitea_config >$synology_gitea_config".out" && mv $synology_gitea_config".out" $synology_gitea_config

########################################################################################################################
# UPDATE INFO FILE
########################################################################################################################
sed -i -e "/^version=/s/=.*/=\"$gitea_target_package_version"-"$spk_version\"/" $project_tmp/INFO
sed -i -e "/^package=/s/=.*/=\"$project_name\"/" $project_tmp/INFO


########################################################################################################################
# UPDATE SCRIPT FILES
########################################################################################################################
sed -i -e "s|__PKG_NAME__|$project_name|g" $project_tmp/scripts/common
sed -i -e "s|__PKG_NAME__|$project_name|g" $project_tmp/package/ui/config

sed -i -e "s|__GITEA_PACKAGE_NAME__|$gitea_target_package_name|g" $project_tmp/scripts/common
sed -i -e "s|__GITEA_PACKAGE_NAME_ESCAPED__|$gitea_target_package_name_escaped|g" $project_tmp/scripts/common
sed -i -e "s|__GITEA_VERSION__|$gitea_target_package_version|g" $project_tmp/scripts/common
sed -i -e "s|__GITEA_SIZE__|$gitea_target_package_download_size|g" $project_tmp/scripts/common

for wizzard_file in $project_tmp/WIZARD_UIFILES/* ; do
  sed -i -e "s|__PKG_NAME__|$project_name|g" $wizzard_file
done

########################################################################################################################
# ADD DOCKER IMAGES
########################################################################################################################
mkdir -p "$project_tmp/package/docker"

if [ -f "docker/$gitea_target_package_name_escaped-$gitea_target_package_version.tar.xz" ]; then
    cp -rf "docker/$gitea_target_package_name_escaped-$gitea_target_package_version.tar.xz" "$project_tmp/package/docker/$gitea_target_package_name_escaped-$gitea_target_package_version.tar.xz"
fi

########################################################################################################################
# PACKAGE BUILD
########################################################################################################################

# compress package dir
cd $project_tmp/package/ && tar -zcf ../package.tgz * && cd ../../

EXTRACTSIZE=$(du -k --block-size=1KB "$project_tmp/package.tgz" | cut -f1)
sed -i -e "/^extractsize=/s/=.*/=\"$EXTRACTSIZE\"/" $project_tmp/INFO

# create spk-name
new_file_name=$project_name"-aio-"$gitea_target_package_version"-"$spk_version".spk"

cd $project_tmp/ && tar --format=gnu -cf $project_build/$new_file_name * --exclude='package' && cd ../
if [ $IS_DEBUG == 0 ]; then
  rm -rf "$project_tmp"
fi
