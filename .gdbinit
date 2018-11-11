source /usr/share/pwndbg/gdbinit.py

python

import sys
import os
sys.path.append(os.path.join(os.environ["HOME"], ".gdb"))

import glm
end
