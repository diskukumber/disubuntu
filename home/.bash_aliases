# --- nala (apt with nice looks) ---
# type `apt`/`sudo apt …` and get nala:
# the trailing space on `sudo` lets the NEXT word expand as an alias,
# so `sudo apt install x` becomes `sudo nala install x`.
# (apt-mark / apt-cache / dpkg have no nala equivalent — use them directly)
alias sudo='sudo '
alias apt='nala'
alias apt-get='nala'
alias i='nala install'
alias r='nala remove'
alias s='nala search'
alias u='nala update'
alias up='nala upgrade'
alias nf='nala fetch'

# --- base ---
alias upg='sudo apt-get upgrade -y'