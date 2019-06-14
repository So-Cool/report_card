* Active Content Manager (ACM) -- if information is not available in logs alter the document context; e.g., if N/A do not print it in the document.
* Natural language data interface.
* Customise the reports based on: who is going to read it, what purpose will it serve, etc.
* Infer which information will be useful/interesting for the end user; e.g., anything abnormal.
* Tune the level of detail of the report card based on the user, i.e. how much detail to include.

All of these can be done via analysing the logs and data to identify and understand:

* what is in the data;
* what can be extracted form the raw data;
* what can be extracted by processing/fusing the raw data; and
* how to use all these data to generate the report card.

---

* Say how long the manipulation task took. Within that, give the exact duration of the time spent on motion planning and the time spent on navigation/perception/etc.
* Include the ratio between successful and failed tasks. Are there any failures at all?
    - `rdf:type = WithFailureHandling`
    - Important details: handle failure clauses in the `failureHandlingClauses` designator property.
    - Use the `caughtFailure` list (and the types of the subsequent failures referenced).
* List all of the tasks that the robot performed. Support that with a pie chart showing how much time each of these took (possibly colour red/green based on whether it succeeded or failed).
* Include the number of different object designators in the logs (get the instances of `rdf:type CRAMDesignator` and look at their counterparts in MongoDB where the designator type is described).
* Get a photo id from the logs and plot the location where the photo was taken on a grid (kitchen plan).
    - `rdf:type = UIMAPerception`
    - Maybe include a sample `capturedImage` in the resulting PDF?
    - Maybe include details from the `perceptionRequest` and `perceptionResult` (e.g., the number of objects).
* Plot the path of the robot overlaid on top of the real room layout.

* Get characteristics of the object you're interested from the mongoDB.

```
mng_obj_pose_by_desig(Obj, Pose) :-
  % TODO: avoid multiple creation of pose instances
  rdf_has(Obj, knowrob:designator, Designator),
  mng_designator_props(Designator, 'POSE', Pose).
```

* List the locations which the robot has visited.

```
?- rdf_has(O, rdf:type, knowrob:'CRAMDesignator'), mng_designator_props(O, 'TYPE', Pose).
O = log:action_aNps5OhhoRap72,
Pose = 'NAVIGATION' ;
O = log:action_wQypcR0HXBb9ri,
Pose = 'TRAJECTORY' ;
null
java.lang.NullPointerException
at org.knowrob.interfaces.mongo.types.PoseFactory.readFromDBObject(PoseFactory.java:52)
at org.knowrob.interfaces.mongo.types.Designator.readFromDBObject(Designator.java:159)
at org.knowrob.interfac
```

* Include a textual description of the manipulation task context.
    - taskContext = PERFORM-ACTION-DESIGNATOR
    - Low-Level action designator performances.
    - How to get the designator properties from the MongoDB using `knowrob_mongo`?

```
rdf_has(O, knowrob:taskContext, literal(type(xsd:string,'PERFORM-ACTION-DESIGNATOR'))),
rdf_has(O, knowrob:designator, D),
mng_designator_props(D, 'TYPE', Pose).
```

---

* Install packs with: `RUN swipl -g 'Os=[interactive(false)],pack_install(blog_core,Os),pack_install(list_util,Os),halt' -t 'halt(1)'`
* Set R home directory with: `:- temporary_directory(TempDirectory), <- 'setwd'(TempDirectory).`
* Get task info with: `task(T), task_duration(T, D), task_outcome(T, O).`
* Load experiments with: `:- load_experiment('./report_card/_data/log1/cram_log.owl').`
* To create a directory use: `dir.create(file.path(mainDir, subDir), showWarnings = FALSE)`

Open questions:

* Where to write the figures from the real interface?
* Can I change the file header to reflect me as a co-author?
* `jpl_array_to_list(AbsolutePositionArray, AbsolutePosition).`
    - What kind of a Java object is it? (At the moment I convert it to an array and return that.)
    - This converts the Java array object `AbsolutePositionArray` to a Prolog list `AbsolutePosition` (which coincides with `[X, Y, Z]`, for example).
    - On the Java side, the array is returned like this:

    ```
    public double[] someFunctionReadingPosition(...) {
       double[] arrReturn = {dX, dY, dZ};

       return arrReturn;
    }
    ```

    - The easy way (used right now) is to read member variables from Java objects on the Java side. Alternatively (a much better approach) the Java object should be retrieved directly from the MongoDB through a predicate in `knowrob_mongo`. (But how?) Then, of course, the above does not work so well.
