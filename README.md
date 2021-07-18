# dt-rename

A [darktable](https://github.com/darktable-org/darktable) script that let's you
rename a whole collection with various variables available, including a numbered
value that is based on the current sorting of the colleciton.

The use case for me is, when I scan a roll of film with my digital camera (or
otherwise), renaming all of the files, and getting the sequence correct manually
is quite annoying. With this script I can use darktable's custom sort to place
the images in the order they appear on the film, and then rename them all at
once, getting the correct file name for my system at the same time.

### Installation

To install, clone or download this repo into the lua subdirectory in your
darktable config directory, which by default is `$HOME/.config/darktable`, and
then enable it in the script manager.

Alternativly navigate to the "install/update scripts" tab in the darktable
script manager, paste `https://github.com/sams96/dt-rename` into the URL
field and click install.

### Usage

A new module, titled "rename" should appear on the right side of the light
table. Enter the new file name pattern you want to use and click "rename
collection". This will rename the entire currently shown collection, *not the
currently selected images*, so be careful. The variables currently available for
the file name patterns are:
 * `{sequence}` - the number of the image in the sequence
 * `{extension}` - the original extension of the file
 * `{filmroll}` - the name of the filmroll that the image is in
