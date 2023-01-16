.PHONY : docker-status docker-create docker-stop docker-rm-container docker-rm-image docker-build-image docker-create docker-start

AUTHOR = alice
REPO = checkers
DOCKER_LABEL = $(REPO)
APP_NAME = $(REPO)
WORK_DIR = $(REPO)
WORK_CLIENT_DIR = client
APP_EXEC = $(REPO)d

docker-build-image:
	@# docker build -f Dockerfile . -t checkers_i
	docker build -f Dockerfile . -t $(DOCKER_LABEL)_i
	docker image ls $(DOCKER_LABEL)_i
	docker run --rm -it $(DOCKER_LABEL)_i ignite version

scaffold-init:
	@# ignite scaffold chain github.com/alice/checkers
	ignite scaffold chain github.com/$(AUTHOR)/$(REPO)

chown:
	sudo chown -R $(whoami):$(whoami) ~/dev/workspace/$(REPO)/*

docker-scaffold-init:
	@echo CAUTION: Command to be initiated only once: when the repo is not created yet! Uncomment last command and initiate that call in the parent directory of the repo to be created.
	@# docker run --rm -it -v $(PWD):/checkers -w /checkers -p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 --name checkers-tmp checkers_i ignite scaffold chain github.com/ja88a/cosmos-icda-checkers
	docker run --rm -it -v $(PWD):/$(WORK_DIR) -w /$(WORK_DIR) -p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 --name $(DOCKER_LABEL)-tmp $(DOCKER_LABEL)_i ignite scaffold chain github.com/$(AUTHOR)/$(REPO)
	sudo chown -R $(whoami):$(whoami) ./$(REPO)

#	---------------------------------------------------------------
#
#	Targets to be initiated from workspace/$(WORK_DIR)
#

docker-serve-tmp:
	@# docker run --rm -it -v $(PWD):/checkers -w /checkers -p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 --name checkers-tmp checkers_i ignite chain serve
	docker run --rm -it \
		-v $(PWD):/$(WORK_DIR) \
		-w /$(WORK_DIR) \
		-p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 \
		--name $(DOCKER_LABEL)-tmp \
		$(DOCKER_LABEL)_i \
		ignite chain serve

docker-create:
	@# docker create --name checkers -i -v $(PWD):/checkers -w /checkers -p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 checkers_i
	docker create --name $(DOCKER_LABEL) -i \
		-v $(PWD):/$(WORK_DIR) \
		-w /$(WORK_DIR) \
		-p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 \
		$(DOCKER_LABEL)_i

docker-create-net:
	docker network create $(DOCKER_LABEL)-net

docker-rm-net:
	docker network rm $(DOCKER_LABEL)-net

docker-serve-net:
	docker run --rm -it \
		-v $(PWD):/$(WORK_DIR) \
		-w /$(WORK_DIR) \
		--network $(DOCKER_LABEL)-net \
		--name $(DOCKER_LABEL)-serve \
		$(DOCKER_LABEL)_i \
		ignite chain serve

# docker-start-net:
# 	docker start $(DOCKER_LABEL)-net

# docker-sh-net:
# 	@# docker exec -it checkers /bin/bash
# 	docker exec -it $(DOCKER_LABEL)-net /bin/bash

docker-start:
	@# docker start checkers
	docker start $(DOCKER_LABEL)

docker-sh:
	@# docker exec -it checkers /bin/bash
	docker exec -it $(DOCKER_LABEL) /bin/bash

docker-serve:
	docker exec -it $(DOCKER_LABEL) ignite chain serve

docker-serve-reset:
	docker exec -it $(DOCKER_LABEL) ignite chain serve --reset-once

docker-status-chain:
	@# docker exec -it checkers checkersd status
	docker exec -it $(DOCKER_LABEL) $(APP_EXEC) status 2>&1 | jq

docker-stop:
	docker stop $(DOCKER_LABEL)

docker-rm-container:
	docker container rm -f $(DOCKER_LABEL)

docker-rm-image: docker-rm-container
	docker image rm -f $(DOCKER_LABEL)_i

docker-init-chain: docker-build-image docker-create docker-start docker-serve

#
# Web GUI - VueJS
#

docker-init-gui:
	docker exec -it $(DOCKER_LABEL) bash -c "cd vue && npm install"

docker-run-gui:
	docker exec -it $(DOCKER_LABEL) bash -c "cd vue && npm run dev -- --host"

#
# Mock
#

docker-mockgen:
	docker exec -it $(DOCKER_LABEL) mockgen -source=x/checkers/types/expected_keepers.go -package testutil -destination=x/checkers/testutil/expected_keepers_mocks.go 

mock-expected-keepers:
	mockgen -source=x/checkers/types/expected_keepers.go \
		-package testutil \
		-destination=x/checkers/testutil/expected_keepers_mocks.go 

#
# TS Client computations
#

install-protoc-gen-ts:
	cd scripts && npm install
	mkdir -p scripts/protoc
	curl -L https://github.com/protocolbuffers/protobuf/releases/download/v21.5/protoc-21.5-linux-x86_64.zip -o scripts/protoc/protoc.zip
	cd scripts/protoc && unzip -o protoc.zip
	rm scripts/protoc/protoc.zip

cosmos-version = v0.45.4

download-cosmos-proto:
	mkdir -p proto/cosmos/base/query/v1beta1
	curl https://raw.githubusercontent.com/cosmos/cosmos-sdk/${cosmos-version}/proto/cosmos/base/query/v1beta1/pagination.proto -o proto/cosmos/base/query/v1beta1/pagination.proto
	mkdir -p proto/google/api
	curl https://raw.githubusercontent.com/cosmos/cosmos-sdk/${cosmos-version}/third_party/proto/google/api/annotations.proto -o proto/google/api/annotations.proto
	curl https://raw.githubusercontent.com/cosmos/cosmos-sdk/${cosmos-version}/third_party/proto/google/api/http.proto -o proto/google/api/http.proto
	mkdir -p proto/gogoproto
	curl https://raw.githubusercontent.com/cosmos/cosmos-sdk/${cosmos-version}/third_party/proto/gogoproto/gogo.proto -o proto/gogoproto/gogo.proto

gen-protoc-ts: download-cosmos-proto install-protoc-gen-ts
	mkdir -p ./client/src/types/generated/
	ls proto/checkers | xargs -I {} ./scripts/protoc/bin/protoc \
		--plugin="./scripts/node_modules/.bin/protoc-gen-ts_proto" \
		--ts_proto_out="./client/src/types/generated" \
		--proto_path="./proto" \
		--ts_proto_opt="esModuleInterop=true,forceLong=long,useOptionals=messages" \
		checkers/{}

docker-client-test-net:
	cd $(WORK_CLIENT_DIR)
	docker run --rm \
		-v $(PWD)/$(WORK_CLIENT_DIR):/$(WORK_CLIENT_DIR) \
		-w /$(WORK_CLIENT_DIR) \
		--network $(DOCKER_LABEL)-net \
		node:18.7 \
		npm test

#
# Keys management - utilities
#

ALICE = $(checkersd keys show alice -a)
BOB = $(checkersd keys show bob -a)

shexport-addr:
	export alice=$(checkersd keys show alice -a)
	@echo alice: $(alice)
	export alice2=$(ALICE)
	@echo ALICE: $(alice2)

	export bob=$(checkersd keys show bob -a)
	export bob=$(BOB)
	@echo bob: $(BOB)