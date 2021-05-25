#!/bin/bash

if [[ "$#" -ne 5 ]]; then
  echo "Usage: $0 IMAGE FOLDER VERSION DATETIME FILE"
  echo "      Example: $0 keptn/api api/ 1.2.3 20210101101210 Dockerfile"
  echo "      Your command: $0 $*"
  exit 1
fi

# todo: not sure if we can use parameters like this
# ${IMAGE}=$1 ${FOLDER}=$2 ${VERSION}=$3 ${DATETIME}=$4 ${FILE}=$5
IMAGE=$1
FOLDER=$2
VERSION=$3
DATETIME=$4
FILE=$5

# store pwd
pwd=$(pwd)

# ensure trailing slash in folder
if [[ "${FOLDER}" != */ ]]; then
  echo "Please ensure that FOLDER has a trailing slash, e.g., ./ or api/"
  exit 1
fi

# ToDo: Where do we get the Manifest from?
echo "Building Docker Image ${IMAGE}:${VERSION}.${DATETIME} from ${FOLDER}${FILE}"

# change into the subfolder where the needed files are hosted
cd ./${FOLDER}

# uncomment certain lines from Dockerfile that are for CI builds only
sed -i '/#travis-uncomment/s/^#travis-uncomment //g' ${FILE}
sed -i '/#build-uncomment/s/^#build-uncomment //g' ${FILE}
cat MANIFEST

docker build . -t "${IMAGE}:${VERSION}.${DATETIME}" -t "${IMAGE}:${VERSION}" --build-arg version="${VERSION}"

if [[ $? -ne 0 ]]; then
  echo "Failed to build Docker Image ${IMAGE}:${VERSION}.${DATETIME}, exiting"
  echo "::error file=${FOLDER}/${FILE}::Failed to build Docker Image"
  exit 1
fi

# push all tags that we just built
docker push "${IMAGE}:${VERSION}.${DATETIME}" && docker push "${IMAGE}:${VERSION}"

if [[ $? -ne 0 ]]; then
  echo "::warning file=${FOLDER}/${FILE}::Failed to push ${IMAGE}:${VERSION}.${DATETIME} to DockerHub, continuing anyway"
  echo "* Failed to push ${IMAGE}:${VERSION}.${DATETIME} and ${IMAGE}:${VERSION} (Source: ${FOLDER})" >> ${pwd}/docker_build_report.txt
else
  echo "* Pushed ${IMAGE}:${VERSION}.${DATETIME} and ${IMAGE}:${VERSION} (Source: ${FOLDER})" >> ${pwd}/docker_build_report.txt
fi

# change back to previous directory
cd ${pwd}
