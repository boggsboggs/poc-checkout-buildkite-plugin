#!/usr/bin/env bats

# Bats documentation https://bats-core.readthedocs.io/en/stable/tutorial.html#quick-installation

export BUILDKITE_BUILD_CHECKOUT_PATH=/tmp/test-checkout-path
export BUILDKITE_REPO="git@github.com:Rippling/rippling-main.git"

setup() {
  export BATS_TESTING=true
  # Make checkout dir an empty directory
  if [[ -d $BUILDKITE_BUILD_CHECKOUT_PATH ]]; then
    rm -rf $BUILDKITE_BUILD_CHECKOUT_PATH
  fi
  mkdir -p $BUILDKITE_BUILD_CHECKOUT_PATH
}


@test "Can source the pre-checkout script" {
  source ./hooks/pre-checkout
}

@test "Run main" {
    source ./hooks/pre-checkout
    git () {
      # mock git clone
      echo "git $@"
      mkdir -p $BUILDKITE_BUILD_CHECKOUT_PATH
      touch $BUILDKITE_BUILD_CHECKOUT_PATH/file
    }
    aws () {
      echo "aws $@"
    }

    read_cache
}

@test "Run read_cache" {
    source ./hooks/pre-checkout
    aws () {
      echo "aws $@"
    }

    read_cache
}


@test "Run update_cache" {
    source ./hooks/pre-checkout
    git () {
      # mock git clone
      echo "git $@"
      mkdir -p $BUILDKITE_BUILD_CHECKOUT_PATH
      touch $BUILDKITE_BUILD_CHECKOUT_PATH/file
    }
    aws () {
      echo "aws $@"
    }
    date () {
      # Cache is not old
      echo "date $@" >&2
      echo '1700426962'
    }

    main
}

@test "Test set_cache_condition noop" {
    source ./hooks/pre-checkout
    mkdir -p $BUILDKITE_BUILD_CHECKOUT_PATH/.git
    set_cache_condition
    [[ $CACHE_CONDITION = 'noop' ]]
}

@test "Test set_cache_condition read" {
    source ./hooks/pre-checkout
    aws () {
      # Cache does exist
      echo "aws $@" >&2
    }
    date () {
      # Cache is not old
      echo "date $@" >&2
      echo '1700426962'
    }
    set_cache_condition
    [[ $CACHE_CONDITION = 'read' ]]
}

@test "Test set_cache_condition read disabled" {
    GIT_CACHE_READ_ENABLED=false
    source ./hooks/pre-checkout
    aws () {
      # Cache does exist
      echo "aws $@" >&2
    }
    date () {
      # Cache is not old
      echo "date $@" >&2
      echo '1700426962'
    }
    set_cache_condition
    [[ $CACHE_CONDITION = 'noop' ]]
}

@test "Test set_cache_condition update" {
    source ./hooks/pre-checkout
    aws () {
      # Cache does not exist
      echo "aws $@" >&2
      return 1
    }
    set_cache_condition
    [[ $CACHE_CONDITION = 'update' ]]

    aws () {
      # Cache does exist
      echo "aws $@" >&2
    }
    date () {
      # Cache is old
      echo "date $@" >&2
      if [[ $1 = '+%s' ]]; then
        echo '1707426962'
      else
        echo '1700426962'
      fi
    }

    set_cache_condition
    [[ $CACHE_CONDITION = 'update' ]]
}

@test "Test set_cache_condition update disabled" {
    GIT_CACHE_UPDATE_ENABLED=false
    source ./hooks/pre-checkout
    aws () {
      # Cache does not exist
      echo "aws $@" >&2
      return 1
    }
    set_cache_condition
    [[ $CACHE_CONDITION = 'noop' ]]

    aws () {
      # Cache does exist
      echo "aws $@" >&2
    }
    date () {
      # Cache is old
      echo "date $@" >&2
      if [[ $1 = '+%s' ]]; then
        echo '1707426962'
      else
        echo '1700426962'
      fi
    }

    set_cache_condition
    [[ $CACHE_CONDITION = 'noop' ]]
}