pacman -Rsn $(pacman -Qdtq)
pacman -Scc
if [ -d "/var/cache/flexo/pkg" ]; then
  paccache -r -k1  $(find /var/cache/flexo/pkg -type d -name x86_64 -printf "-c %p ")
fi

