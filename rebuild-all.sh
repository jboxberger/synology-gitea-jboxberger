#!/bin/bash
IS_DEBUG=""

########################################################################################################################
# PARAMETER HANDLING
########################################################################################################################
for i in "$@"
do
    case $i in
        --debug)
            IS_DEBUG="--debug"
        ;;
        *)
            # unknown option
        ;;
    esac
    shift
done

spk_version=0100

gitea_package_name="gitea/gitea"
declare -A versions;      declare -a orders;
versions["1.4"]="34"; orders+=( "1.4" )

mariadb_package_name="mariadb"
declare -A mariadb_sizes
mariadb_sizes["10.3.5"]="136"

for i in "${!orders[@]}"
do
    gitea_version=${orders[$i]}
    gitea_size=${versions[${orders[$i]}]}
    gitea_package_fqn=$gitea_package_name:$gitea_version

    mariadb_version="10.3.5"
    mariadb_size=${mariadb_sizes[$mariadb_version]}
    mariadb_package_fqn=$mariadb_package_name:$mariadb_version

    echo "building $gitea_package_fqn ("$gitea_size"MB) with $postgresql_package_fqn ("$postgresql_size"MB), $mariadb_package_fqn ("$mariadb_size"MB)"
    ./build.sh --gitea-fqn=$gitea_package_fqn --gitea-download-size=$gitea_size \
       --mariadb-fqn=$mariadb_package_fqn --mariadb-download-size=$mariadb_size \
       --spk-version=$spk_version \
       "$IS_DEBUG"
done
