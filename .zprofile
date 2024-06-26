# Define login environment on first login shell.
#
export LANG="en_CA.UTF-8"
export LC_ALL="en_CA.UTF-8"
export LC_CTYPE="UTF-8"

if [[ ! -v TMUX ]]; then
    export TERM=xterm-256color

    export WIKI="$HOME/Documents/Wiki"
    export CODEPATH="$HOME/Code"
    export WORKSPACES="$HOME/Work:$CODEPATH"
    export GOPATH="$CODEPATH/go"
    export LUA_PATH="$HOME/.luarocks/share/lua/5.3/?.lua;;"

    export PATH="$PATH:$HOME/.cargo/bin:$HOME/.gem/ruby/2.5.0/bin:$GOPATH/bin"
    export RIPGREP_CONFIG_PATH="$HOME/.config/ripgreprc"

    # Perl.
    PERLBASE="$CODEPATH/perl"
    PERL5LIB="$PERLBASE/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
    PERL_LOCAL_LIB_ROOT="$PERLBASE${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
    PERL_MB_OPT="--install_base \"/$PERLBASE\""; export PERL_MB_OPT;
    PERL_MM_OPT="INSTALL_BASE=$PERLBASE"; export PERL_MM_OPT;
fi
