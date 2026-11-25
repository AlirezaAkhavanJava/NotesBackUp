

When people say "Spring's layered architecture," they usually mean **Controller → Service → Repository**: the Controller receives an HTTP request, the Service holds business logic, and the Repository talks to the database. That's not MVC. That's just a layering convention for organizing backend code into responsibilities.

**MVC (Model-View-Controller)** is a different, older pattern about _how a request turns into a response the user can look at_. It only has three pieces, and none of them is "the database layer" or "the business logic layer":

- **Model** — the data for this particular request. Not your whole database — just the plain data object being handed to the page. In Spring, this is usually a `Map` or a Java object you stuff values into before handing control to a template.
- **View** — the thing that turns that data into something visible: HTML, in most Spring MVC apps (a Thymeleaf template, a JSP). The View's only job is rendering — it shouldn't contain business logic.
- **Controller** — the referee. It receives the HTTP request, decides what data is needed (often by calling a Service), puts that data into the Model, and picks which View should render it.

Here's what that actually looks like in a Spring Boot app using server-rendered HTML (as opposed to a `@RestController` returning JSON):

```java
@Controller
public class UserPageController {

    private final UserService userService; // business logic lives here, not in the Controller

    public UserPageController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/users/{id}")
    public String showUser(@PathVariable Long id, Model model) {
        User user = userService.findById(id);   // ask the Service for data
        model.addAttribute("user", user);        // put it in the Model
        return "user-details";                   // name of the View (user-details.html template)
    }
}
```

`Model model` here is literally Spring's name for the M in MVC — a small bag of attributes for this one request. `"user-details"` is the name of a Thymeleaf template file; Spring resolves it and renders it as HTML using the data you put in the Model. The `Controller` never generates HTML itself — it just decides _what_ data and _which_ template.

So to place it precisely: the Controller → Service → Repository layering is about organizing your _backend logic_. MVC is specifically about the last step — how a Controller hands data to a View to produce output. A `@RestController` returning JSON (which is what most of your other notes have been about) skips the View step entirely — there's no HTML template, no rendering, just data serialized straight to JSON. That's still "the Controller" from MVC's perspective, but there's no View in the picture at all, which is part of why it's easy to lose track of what View even means in a typical Spring Boot REST API project — you may simply never have written one.

Now, MVP and MVVM only make sense once that's clear, because they're not alternate backend architectures — they're alternate answers to one specific question: _"when the Controller/middleman has new data, how does the View find out about it?"_ All three patterns share the same Model and View concepts above; they differ only in the middle piece.

**MVC's answer:** the Controller picks a View and hands it data once, up front, before rendering starts. There's no back-and-forth — the Controller renders the page and is done.

**MVP's answer:** the middleman (now called a _Presenter_) keeps a reference to the View and calls methods on it directly, whenever something changes — not just once at the start.

```java
interface UserView {
    void showUserName(String name);
}

class UserPresenter {
    private final UserView view;
    private final UserService userService;

    UserPresenter(UserView view, UserService userService) {
        this.view = view;
        this.userService = userService;
    }

    void loadUser(Long id) {
        User user = userService.findById(id);
        view.showUserName(user.getName()); // Presenter explicitly pushes data to the View
    }
}
```

Notice `UserPresenter` depends on an interface, `UserView` — not a concrete UI class. That's the one new thing MVP adds beyond MVC: the View is now something the middleman holds a reference to and can call at any time, not just a destination picked once per request.

**MVVM's answer:** the middleman (now called a _ViewModel_) doesn't call the View at all. It just exposes its data as an observable property, and the View watches that property and updates itself automatically when it changes.

```java
class UserViewModel {
    private final ObservableValue<String> userName = new ObservableValue<>("");
    private final UserService userService;

    UserViewModel(UserService userService) {
        this.userService = userService;
    }

    ObservableValue<String> userNameProperty() {
        return userName;
    }

    void loadUser(Long id) {
        User user = userService.findById(id);
        userName.set(user.getName()); // ViewModel only updates its own state
    }
}
```

The new thing here: `UserViewModel` never references a View type at all — not even an interface. It just mutates `userName`, and whatever is subscribed to that property (the View) reacts on its own.

One important fact to hold onto: MVP and MVVM are UI-side patterns — they show up in Android apps, JavaFX/Swing desktop apps, and modern JS frontends (React, Vue). They are _not_ things you'll find built into Spring Boot's web layer, because a typical Spring Boot app either renders a full page once (classic MVC with Thymeleaf) or returns raw JSON (`@RestController`, no View at all). You'd only reach for MVP or MVVM if you were writing the _client_ that consumes your Spring Boot API — say, an Android app or a JavaFX desktop client — where the UI needs to update repeatedly in response to changing data, not just render once per request.


[[Spring Framework]]