export CODEPATH="$HOME/Code"
export GOPATH="$CODEPATH/go"
export LANG="en_CA.UTF-8"
export LC_ALL="en_CA.UTF-8"
export TERM=xterm-256color
export WORKSPACES="$HOME/Work:$CODEPATH" # workon
export PATH="$PATH:~/.cargo/bin:~/.gem/ruby/2.5.0/bin:$GOPATH/bin:$HOME/.bin/BurpSuitePro"

PERLBASE="$CODEPATH/perl"
PERL5LIB="$PERLBASE/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="$PERLBASE${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/$PERLBASE\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=$PERLBASE"; export PERL_MM_OPT;

# START X IF REQUIRED
if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
  exec startx
fi

