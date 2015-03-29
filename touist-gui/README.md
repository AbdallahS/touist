TouIST main program
===================

This folder contains the source code for the main program of the TouIST project. It is named "ui" because of it's main feature : be the user interface for the solver and "bigand" translator.

## Create a new project with your IDE 
**I recommend to create a new project in your IDE with the starting point `./touist-gui` instead of your touist-project-root-folder.** Do not keep your old project file (Netbeans, Eclipse...).

NOTE: if you run your project at the `./touist-gui/` parent folder (the touist-project-root-folder), you may have problems with paths
NOTE: For now on, **I will write `./` instead of `./touist-gui`**.

With Netbeans:
![image](http://img15.hostingpics.net/pics/611633Capturedcran20150329183200.png)
Then go to 

## Build and run the touist-gui project
###1. Check the `classpath`
Make sure your IDE (eclipse, netbeans...) knows the right _classpath_:

1. Every `.jar` in `./libs/` must be **INDIVIDUALLY** in the classpath
2. The `./build` path (or any folder in which you build the project) must be in the classpath
3. The `./ressources` folder (for the .xml file ressource)

In Eclipse, you can check that in project properties > java build path > Build tab.

###2. Check `external` and `ressources` folders
To run the whole thing, check first what is the _running_ directory. In Eclipse or Netbeans, the running directory is the root folder of your project. We will call it `./` from now on.
Now, check if the following external binaries/jars are at the right place:

1. If you run `TouIST.class` from `./` (meaning the `./touist-gui` folder)
  - you must have `./external/touistc` (get it [from the Drive](https://drive.google.com/folderview?id=0B5mz8k-t6PT0cW5FSTBxNmgxUjQ&usp=sharing) and rename it `touistc`)
  - you must have `./external/minisat.jar`
  - you must have `./ressources/touistTheme.xml`
2. If you run `Touist.class` from your touist-project-root-folder, then you might have to copy everything I just mentioned on the previous segment 

##3. Use `build.xml` with `Ant`
The `build.xml` contains the different targets needed for compilation and distribution. I use it with Eclipse, but it can also be used by anybody (you must install `ant` though).

To build: `ant build`
To run: `ant run`
To build the .jar: `ant build-jar`
To prepare the `./dist` folder: `ant dist`

Note: **`ant dist`** does almost nothing. It just copies the `touist.jar` file to `./dist` and then copies everything from `./external` into `./dist`.

## Conception/architecture
![conception](https://www.lucidchart.com/publicSegments/view/54f46f57-1ff4-46e0-b146-65000a009e9c/image.png)