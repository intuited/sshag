#!/bin/sh

# acquired courtesy of
# http://superuser.com/questions/141044/sharing-the-same-ssh-agent-among-multiple-login-sessions#answer-141241

main() {
	# If we are not being sourced, but rather running as a subshell,
	# let people know how to use the output.
	if [ "${0#*sshag}" != "$0" ]; then
		sshag_msg='Output should be assigned to the environment variable $SSH_AUTH_SOCK.'
		sshag "$@"
	fi
}

sshag() {
	# ssh agent sockets can be attached to an ssh daemon process
	# or an ssh-agent process.

	sshag_require_ssh
	unset agent_found
	unset agent_socket
	unset user_hostname

	# check any params
	while [ -n "$1" ]; do
		if [ -e "$1" ] ; then
			[ -S "$1" ] && agent_socket="$1"
		else
			user_hostname="$1"
		fi
		shift
	done

	# Attempt to use socket passed in, or
	#   find and use the ssh-agent in the current environment
	if sshag_vet_socket "$agent_socket"; then
		agent_found=1
	else
		# If there is no agent in the environment,
		# search for possible agents to reuse
		# before starting a fresh ssh-agent process.
		for agent_socket in $(sshag_get_sockets) ; do
			sshag_vet_socket "$agent_socket" && agent_found=1 && break
		done
	fi

	# If at this point we still haven't located an agent,
	# then it's time to start a new one
	[ -z "$agent_found" ] &&  eval "$(ssh-agent)"

	if [ -n "$user_hostname" ]; then
		sshag_do_ssh "$user_hostname"
	else
		# Display the found socket
		if [ "$sshag_msg" ]; then
			print_stderr "$sshag_msg"
			unset sshag_msg
		fi

		# Display keys currently loaded in the agent
		print_stderr "Keys:"
		print_stderr "$(ssh-add -l | sed 's/^/    /')"

		print_line "$SSH_AUTH_SOCK"
	fi

	# Clean up
	unset agent_found
	unset agent_socket
	unset user_hostname
}

sshag_require_ssh() {
	if [ ! -x "$(command -v ssh)" ]; then
		exit_error "'ssh' is not available! Aborting!"
	elif [ ! -x "$(command -v ssh-add)" ]; then
		exit_error "'ssh-add' is not available! Aborting!"
	elif [ ! -x "$(command -v ssh-agent)" ]; then
		exit_error "'ssh-agent' is not available! Aborting!"
	fi
}

sshag_vet_socket() {
	[ "$1" ] && export SSH_AUTH_SOCK="$1"

	if [ -z "$SSH_AUTH_SOCK" ]; then
		return 1
	elif [ -S "$SSH_AUTH_SOCK" ]; then
		ssh-add -l >/dev/null 2>&1
		if [ $? -eq 2 ]; then
			rm -f "$SSH_AUTH_SOCK"
			print_warning "Socket '$SSH_AUTH_SOCK' is dead!  Deleting!"
		fi
	else
		print_warning "'$SSH_AUTH_SOCK' is not a socket!"
	fi
}

sshag_get_sockets() {
	# OpenSSH only uses these two dirs
	for dir in '/tmp' "$TMPDIR"; do
		find "$dir" -user $(id -u) -type s -path '*/ssh-*/agent.*' 2>/dev/null
	done | sort -u
}

# Load first key for specified user@hostname and start `ssh`.
sshag_do_ssh() {
	# This is needed for OpenSSH before v7.2 which added support AddKeysToAgent
	# Or if the local ssh client support AddKeysToAgent,
	# but it is not set in the ~/.ssh/config

	# OpenSSH v7.2 added support for AddKeysToAgent.
	# Honor it if it is used in ssh_config.
	# Otherwise, attempt to load identityfile as user may use a common ssh_config
	# on multiple machines where only some support AddKeysToAgent.
	# (OpenSSH before v7.2 barfs on params it doesn't know about so can't use
	# it in a common ssh_config where some machines have pre v7.2 OpenSSH.)

	if sshag_config_has_add_keys; then
		# Honor AddKeysToAgent settings
		: # do nothing
	elif ssh -o AddKeysToAgent 2>&1 | grep 'missing argument' >/dev/null; then
		# If this ssh supports AddKeyToAgent, then use it
		sshag_args='-o AddKeysToAgent=yes'
	else
		# This is needed for OpenSSH pre v7.2, when AddKeysToAgent was added
		sshag_add_key_to_agent "$1"
	fi

	ssh "$sshag_args" "$1"
	unset sshag_args
}

# Checks is ~/.ssh/config has
sshag_config_has_add_keys() {
	grep '^[[:blank:]]*AddKeysToAgent' \
		"$HOME/.ssh/config" "/etc/ssh/ssh_config" >/dev/null
	return $?
}

sshag_add_key_to_agent() {
	# This is needed for OpenSSH before v7.2 which added support AddKeysToAgent
	# Or if the local ssh client support AddKeysToAgent,
	# but it is not set in the ~/.ssh/config

	# check if identity is already loaded
	if ! sshag_is_identity_loaded "$1"; then

		# load identity if one is defined for the user@hostname.
		sshag_get_identity "$1"
		if [ -n "$sshag_identity" ] && ! ssh-add "$sshag_identity"; then
			print_error "Unable to load identity '$sshag_identity'!"
		fi
	fi

	# Clean up
	unset sshag_identity
}

sshag_is_identity_loaded() {
	echo 'exit' | ssh -o BatchMode=yes -- $1 2>/dev/null
	#[ $? -eq 0 ] && return 0 || return 1
	return $?
}

# SETS identity
sshag_get_identity() {
	#identity="$(ssh -G $1 | awk ' /identityfile/ { print $2 } ' | head -n 1)"
	sshag_identity="$(ssh -v -o BatchMode=yes "$1" 2>&1 \
			| awk ' /identity file/ { print $4 } ' \
			| head -n 1)"

	if [ -n "$sshag_identity" ]; then
		# leading tilde causes `ssh-add` to fail.
		sshag_identity="$(expand_tilde "$sshag_identity")"
	fi
}

# HELPERS

# Call in a subshell
expand_tilde() {
	expand_tilde_="${1#\~/}"
	[ "$1" != "$expand_tilde_" ] && expand_tilde_="$HOME/$expand_tilde_"
	printf "$expand_tilde_"
	unset expand_tilde_
}

exit_error() {
	print_error "$@"
	exit 1
}

print_error() {
	print_stderr "ERROR: $@"
	return 1
}

print_line() {
	printf "$@\n"
}

# Do not send messages to 'stdout'
# - it is reserved for outputting $SSH_AUTH_SOCH when invoked in a subshell
print_stderr() {
	print_line "$@" >&2
}

print_warning() {
	print_stderr "WARNING: $@"
	return 1
}

main "$@"
