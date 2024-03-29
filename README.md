REPOSITORY DESCRIPTION
----------------------

This repository will contain small (or quite big) pieces of MATLAB code I 
wrote to simplify my everyday life at work. You can reuse it freely under
the terms of the GPL version 3 (see the LICENSE file of this repository,
or below for a short note).

REPOSITORY INDEX
----------------

- `chdir.m`: `cd` with an history. Using `chdir('-')` returns to 
previously visited directories.
- `fullpath.m`: Returns the absolute (aka full) path to the same 
location as the given path (may already be absolute).
- `mosaicFigure.m`: Creates a new figure which occupies as much screen 
as possible instead of being stacked on the previously created figures.
- `parseProperties.m`: Parses a property-value list and check the values 
respect some given constraints.
- `strjoin.m`: A MATLAB implementation of the function gluing strings 
together.
- `stringSplit.m`: A MATLAB imlementation if the function splitting 
strings at delimiter positions.
- `iff.m`: A MATLAB implementation of the inline if constuct similar to
C-based languages ternary operator.
- `select.m`: Filters elements of a array (cell or numeric array) based on 
a criterion.
- `slwho.m`: List and locate existing variables in MATLAB and Simulink.
- `taskList.m`: List processes running on a Windows host.

LICENSING INFORMATION
---------------------
These programs are free software: you can redistribute them and/or modify
them under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

These programs are distributed in the hope that they will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
