

**MVP (Model-View-Presenter)** and **MVVM (Model-View-ViewModel)** are two architecture patterns for apps that have a user interface, such as desktop apps, mobile apps and browser front ends. Both are cousins of the MVC you studied in your MVC note. They keep the same goal, separating _what is shown_ from _what the app knows and decides_, but they change who sits in the middle and how the screen gets updated.

In both patterns, the screen (the **View**) is kept as dumb as possible, so that the real logic can live in a plain class you can test without opening any window. MVP does that with a **Presenter** that tells the View what to show. MVVM does it with a **ViewModel** that the View watches and binds to automatically. This note teaches each one, then compares them.

---

## First, the problem they solve

In a UI app, the easy mistake is to put logic directly in the screen code: validation, formatting, loading data, deciding which button is enabled. Then:

- You can't test that logic without launching the UI.
- The screen class grows huge and tangled.
- Changing the data layer breaks the screen.

MVC helps in a server app, where a controller handles a request and returns a response (as in your Spring MVC note). But in a UI app that stays open and keeps reacting to the user, the View and the logic still tend to get mixed together. MVP and MVVM are two fixes for that.

---

## MVP: the Presenter tells the View what to show

### The roles

|Part|Job|
|---|---|
|**Model**|The data and business rules (the same as in MVC)|
|**View**|A **passive** screen. It shows what it's told and forwards user actions. It contains no logic|
|**Presenter**|All the UI logic. It reads from the Model and **commands** the View|

The View hides behind an **interface**, and the Presenter talks only to that interface. This is the key idea of MVP.

### The flow

```text
User clicks "Load"
      │
      ▼
   View ── forwards the event ──►  Presenter ── asks ──►  Model
                                        │                    │
   View ◄── view.showName("Ali") ───────┘◄──── data ─────────┘
```

The View never talks to the Model directly. Everything goes through the Presenter, and the Presenter updates the View **by calling its methods**.

### In Java

```java
public interface UserView {                 // what the Presenter is allowed to ask of a screen
    void showName(String name);
    void showError(String message);
}

public class UserPresenter {
    private final UserView view;
    private final UserRepository model;

    public UserPresenter(UserView view, UserRepository model) {
        this.view = view;
        this.model = model;
    }

    public void onLoadClicked(long id) {
        try {
            view.showName(model.findById(id).getName());
        } catch (UserNotFoundException e) {
            view.showError("User not found");
        }
    }
}
```

Line by line:

- `UserView` is the only thing the Presenter knows about the screen. Any screen (a window, a web page, a test fake) can implement it.
- The Presenter holds the logic: what to do on a click, and what to show on an error.
- The real screen class just implements `showName` and `showError` and calls `presenter.onLoadClicked(id)` when the button is pressed.

**Testing needs no UI.** You pass a fake view:

```java
class FakeView implements UserView {
    String shownName; String shownError;
    public void showName(String n) { shownName = n; }
    public void showError(String m) { shownError = m; }
}
```

Then you call `presenter.onLoadClicked(1)` and assert that `shownName` is `"Ali"`. That is the main payoff.

### Strengths and costs

- Strong: very testable, and the View is trivially simple.
- Cost: an interface per screen and a lot of "tell the view to do X" calls. A Presenter can also swell into a "fat presenter" that does too much.
- A common variant, the **Supervising Controller**, lets the View handle simple bindings itself. The strict version above is the **Passive View**.

---

## MVVM: the View binds to a ViewModel

### The roles

|Part|Job|
|---|---|
|**Model**|The data and business rules|
|**View**|The screen. It **binds** to values and commands exposed by the ViewModel|
|**ViewModel**|Holds the screen's **state** as observable values, plus the actions the user can trigger. It knows **nothing** about the View|

The difference from MVP is the direction of knowledge. In MVP, the Presenter holds the View (through an interface) and commands it. In MVVM, the ViewModel has **no reference** to the View at all. Instead, the View watches the ViewModel, and a **data binding** mechanism keeps the two in sync.

### The flow

```text
User clicks "Load"
      │
      ▼
   View ── runs a command ──►  ViewModel ── asks ──►  Model
                                    │                    │
                       sets observable state  ◄──── data ┘
                                    │
   View ◄──── binding updates the screen automatically
```

You never write "now update the label." You change the state, and the binding updates the screen.

### In Java (JavaFX has binding built in)

```java
public class UserViewModel {
    private final StringProperty name  = new SimpleStringProperty("");
    private final StringProperty error = new SimpleStringProperty("");
    private final UserRepository model;

    public UserViewModel(UserRepository model) { this.model = model; }

    public StringProperty nameProperty()  { return name; }
    public StringProperty errorProperty() { return error; }

    public void load(long id) {
        try {
            name.set(model.findById(id).getName());
            error.set("");
        } catch (UserNotFoundException e) {
            error.set("User not found");
        }
    }
}
```

```java
// In the View (the screen code):
nameLabel.textProperty().bind(viewModel.nameProperty());     // label follows the state
errorLabel.textProperty().bind(viewModel.errorProperty());
loadButton.setOnAction(e -> viewModel.load(id));
```

Line by line:

- Each `StringProperty` is an **observable** value: it tells anyone watching when it changes.
- `bind(...)` connects a label to a property. After that, `name.set("Ali")` changes the screen with no further code.
- The ViewModel imports nothing about labels or buttons, so you test it by calling `load(1)` and checking `nameProperty().get()`.

MVVM is the pattern behind WPF/XAML (where it began), Android's `ViewModel` with `LiveData` or `StateFlow`, SwiftUI, and Vue and Angular on the web. (React is a related idea, but it isn't classic MVVM.)

### Strengths and costs

- Strong: very little glue code, testable, and several views can share one ViewModel.
- Cost: data binding feels like magic, and it's harder to debug ("why did this label change?"). Overused two-way bindings can create tangled update chains.

---

## Side by side

||MVC|MVP|MVVM|
|---|---|---|---|
|Middle part|Controller|Presenter|ViewModel|
|Does the middle part know the View?|Loosely|**Yes**, through an interface|**No**|
|How the View updates|The View reads the Model, or the controller picks a view|The Presenter **calls** View methods|**Binding** updates it automatically|
|Does the View talk to the Model?|Often|Never|Never|
|Testing|Good|Very good (fake view)|Very good (just state)|
|Glue code|Low|Higher|Lowest, if you have binding|
|Typical home|Server-side web|Older Android, WinForms|WPF, modern Android, Vue/Angular, SwiftUI|

A quick way to remember: **MVP pushes** updates into the View by command, and **MVVM lets the View pull** updates through binding.

---

## Where these fit with Spring Boot

Spring MVC is the **server-side** MVC: a request arrives, a controller returns a page or JSON, and the response ends the story. MVP and MVVM are mostly about **the client UI** that stays open. If you build a Spring Boot REST API with a separate front end, as in your REST API notes, the Spring side stays "controller → service → repository", and the JSON it returns is the **Model** the front end consumes. The front end, whether Angular, Vue or an Android app, is where MVVM (or MVP) applies.

---

## Mistakes to avoid

- **Letting the ViewModel hold a reference to the View** (a label, a screen, an Android `Context`). That breaks the whole point and can leak memory.
- **A fat Presenter.** If it has hundreds of lines, split it into smaller ones or move the rules into the Model.
- **Business rules in the ViewModel or Presenter.** They handle _UI logic_ (what to show). Real business rules belong in the Model.
- **Using a pattern where none is needed.** A tiny screen doesn't need a Presenter or ViewModel.

---

## Which one to choose

|Situation|Choose|
|---|---|
|Your framework has data binding (JavaFX, WPF, Android, Vue, Angular, SwiftUI)|**MVVM**|
|No binding, or you want to control every UI update explicitly|**MVP**|
|A server-rendered web app (Spring MVC with Thymeleaf)|**MVC**|

---

## Related concept in short

**The Observer pattern** is what makes MVVM's binding work. An object (the _subject_, here a property) keeps a list of watchers and notifies them whenever it changes. JavaFX properties, `LiveData` and Vue's reactivity are all observers with convenient wrappers.




[[Spring Framework]]