PLUGIN_NAME=alexeykhodos/nexentastor-nfs-plugin
PLUGIN_TAG=latest


all: clean docker rootfs create enable push


clean:
	@echo "### rm ./plugin"
	@rm -rf ./plugin

docker:
	@echo "### docker build: builder image"
	@docker build -q -t builder -f Dockerfile.dev .
	@echo "### extract nvd"
	@docker create --name tmp builder
	@docker start -i tmp
	@docker cp tmp:/go/bin/nvd .
	@docker rm -vf tmp
	@docker rmi builder
	@echo "### docker build: rootfs image with nvd"
	@docker build -q -t ${PLUGIN_NAME}:rootfs .

rootfs:
	@echo "### create rootfs directory in ./plugin/rootfs"
	@mkdir -p ./plugin/rootfs
	@docker create --name tmp ${PLUGIN_NAME}:rootfs
	@docker export tmp | tar -x -C ./plugin/rootfs
	@echo "### copy config.json to ./plugin/"
	@cp config.json ./plugin/
	@docker rm -vf tmp

create:
	@echo "### remove existing plugin ${PLUGIN_NAME}:${PLUGIN_TAG} if exists"
	@docker plugin rm -f ${PLUGIN_NAME}:${PLUGIN_TAG} || true
	@echo "### create new plugin ${PLUGIN_NAME}:${PLUGIN_TAG} from ./plugin"
	@docker plugin create ${PLUGIN_NAME}:${PLUGIN_TAG} ./plugin

enable:
	@echo "### enable plugin ${PLUGIN_NAME}:${PLUGIN_TAG}"
	@docker plugin enable ${PLUGIN_NAME}:${PLUGIN_TAG}

push:  clean docker rootfs create enable
	@echo "### push plugin ${PLUGIN_NAME}:${PLUGIN_TAG}"
	@docker plugin push ${PLUGIN_NAME}:${PLUGIN_TAG}
