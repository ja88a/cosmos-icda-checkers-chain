.PHONY : docker-status docker-create docker-stop docker-rm-container docker-rm-image docker-build-image docker-create docker-start

AUTHOR = alice
REPO = checkers
DOCKER_LABEL = $(REPO)
APP_NAME = $(REPO)
WORK_DIR = $(REPO)
APP_EXEC = $(REPO)d

docker-build-image:
	# docker build -f Dockerfile . -t checkers_i
	docker build -f Dockerfile . -t $(DOCKER_LABEL)_i
	docker image ls $(DOCKER_LABEL)_i
	docker run --rm -it $(DOCKER_LABEL)_i ignite version

scaffold-init:
	# ignite scaffold chain github.com/alice/checkers
	ignite scaffold chain github.com/$(AUTHOR)/$(REPO)

docker-scaffold-init:
	echo CAUTION: Command to be initiated only once: when the repo is not created yet! Uncomment last command and initiate that call in the parent directory of the repo to be created.
	# docker run --rm -it -v $(PWD):/checkers -w /checkers -p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 --name checkers-tmp checkers_i ignite scaffold chain github.com/ja88a/cosmos-icda-checkers
	docker run --rm -it -v $(PWD):/$(WORK_DIR) -w /$(WORK_DIR) -p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 --name $(DOCKER_LABEL)-tmp $(DOCKER_LABEL)_i ignite scaffold chain github.com/$(AUTHOR)/$(REPO)
	sudo chown -R $(whoami):$(whoami) ./$(REPO)

#	---------------------------------------------------------------
#
#	Targets to be initiated from workspace/$(WORK_DIR)
#

docker-serve-tmp:
	# docker run --rm -it -v $(PWD):/checkers -w /checkers -p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 --name checkers-tmp checkers_i ignite chain serve
	docker run --rm -it -v $(PWD):/$(WORK_DIR) -w /$(WORK_DIR) -p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 --name $(DOCKER_LABEL)-tmp $(DOCKER_LABEL)_i ignite chain serve

docker-create:
	# docker create --name checkers -i -v $(PWD):/checkers -w /checkers -p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 checkers_i
	docker create --name $(DOCKER_LABEL) -i -v $(PWD):/$(WORK_DIR) -w /$(WORK_DIR) -p 1317:1317 -p 3000:3000 -p 4500:4500 -p 5000:5000 -p 26657:26657 $(DOCKER_LABEL)_i

docker-start:
	# docker start checkers
	docker start $(DOCKER_LABEL)

docker-sh:
	# docker exec -it checkers /bin/bash
	docker exec -it $(DOCKER_LABEL) /bin/bash

docker-serve:
	docker exec -it $(DOCKER_LABEL) ignite chain serve

docker-serve-reset:
	docker exec -it $(DOCKER_LABEL) ignite chain serve --reset-once

docker-status-chain:
	# docker exec -it checkers checkersd status
	docker exec -it $(DOCKER_LABEL) $(APP_EXEC) status 2>&1 | jq

docker-stop:
	docker stop $(DOCKER_LABEL)

docker-rm-container:
	docker container rm -f $(DOCKER_LABEL)

docker-rm-image: docker-rm-container
	docker image rm -f $(DOCKER_LABEL)_i

docker-init-chain: docker-build-image docker-create docker-start docker-serve

docker-init-gui:
	docker exec -it $(DOCKER_LABEL) bash -c "cd vue && npm install"

docker-run-gui:
	docker exec -it $(DOCKER_LABEL) bash -c "cd vue && npm run dev -- --host"
