Use Apple's Computer Vision Optical Character Recognition to automatically extract text from a folder of chronologically-ordered images.

The images must be saved in the order you want them to be extracted. The program will start with the oldest and move to the newest.

It will output a .txt file.

```
swiftc -framework CoreGraphics main.swift -o ImageFileReader
./ImageFileReader my/directory/folder filename
```
