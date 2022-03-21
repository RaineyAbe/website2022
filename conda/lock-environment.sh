#!/usr/bin/env bash
# This script will re-generate reproducible lockfiles
# Execution needs to be from inside the `conda` folder

ENV_FILE="environment.yml"
LOCK_ENV='CondaLock'

# Generate CondaLock environment unless present
conda env list | grep ${LOCK_ENV} > /dev/null

if [[ $? -eq 1 ]]; then
  conda create -q -y -n ${LOCK_ENV} -c conda-forge conda-lock=1.0.3 mamba=0.22
fi

# https://github.com/conda/conda/issues/7980#issuecomment-492784093
eval "$(conda shell.bash hook)"
conda activate ${LOCK_ENV}

if [[ ! -s "${ENV_FILE}" ]]; then
    >&2 printf " Missing ${ENV_FILE} to generate environments with\n"
    >&2 printf " Are you inside the 'conda' folder?\n"
    exit 1
fi

# Local environments
## Generate explicit lock files
conda-lock lock --mamba -f ${ENV_FILE}

# BinderHub support
## Generate environment.yml for binder compatibility
printf "Generate environment.yml for BinderHub \n"
conda-lock render -k env

# Temporary fix for https://github.com/conda-incubator/conda-lock/issues/172
sed -i.bak -r 's/--hash=md5:None//' conda-linux-64.lock.yml
sed -i.bak -r 's/--hash=md5:None//' conda-osx-64.lock.yml
rm *.yml.bak

# Temporary fix for https://github.com/conda-incubator/conda-lock/issues/171
echo "    - git+https://github.com/fastice/nisardev.git@4fa6429a93b6716e4e7a6522d98340b9966d7d9d" >> conda-linux-64.lock.yml
echo "    - git+https://github.com/fastice/nisardev.git@4fa6429a93b6716e4e7a6522d98340b9966d7d9d" >> conda-osx-64.lock.yml
echo "    - git+https://github.com/fastice/grimpfunc.git@512a8d35731c83771e74cbd5b0ade273fff680bd" >> conda-linux-64.lock.yml
echo "    - git+https://github.com/fastice/grimpfunc.git@512a8d35731c83771e74cbd5b0ade273fff680bd" >> conda-osx-64.lock.yml

# Remove CondaLock environment when the last command was successful
if [[ $? -eq 0 ]]; then
  conda deactivate
  conda remove -q -y --name ${LOCK_ENV} --all
fi