
# What a "ticket" is



## The core intuition

Think of a **restaurant order slip**. A waiter doesn't shout "make something for table 4" at the kitchen. They write the order on a slip with a number, and the slip travels through the kitchen: received, cooking, ready, served. Anyone can look at the slip and know what was asked for, who's working on it, and whether it's done.

A **ticket** is that slip for software work. It's one written unit of work (a bug to fix, a feature to build, a task to do), with a number, so a team can track it from "someone asked for this" to "it's live."

## The story

You join a team that runs a booking app. Your lead doesn't tap you on the shoulder and say "the seats thing is broken, can you look?" Instead you open the team's board, where a ticket is waiting, assigned to you:

```
BOOK-212  |  Bug  |  Priority: High
Title:    Customer booked into the wrong seat
Steps:    1. Open the booking page  2. Pick any row with several free seats
Expected: first free seat is booked
Actual:   last free seat is booked
Status:   To Do  ->  assigned to you
```

You move it to **In Progress**, and then the ticket number starts appearing everywhere your work goes:

```bash
git checkout -b BOOK-212-fix-seat-selection          # branch named after the ticket
git commit -m "BOOK-212: stop search at first free seat"   # commit message links back to it
git push                                              # pull request: "Fixes BOOK-212"
```

The **surprise** comes during code review. A teammate comments: _"This looks right, but BOOK-198 reported the same symptom and was closed as 'cannot reproduce'. Did you check whether it's the same root cause?"_ Because both tickets are searchable, you find BOOK-198 in seconds. It contains a log snippet from a customer's report that confirms your diagnosis. You link the two tickets as duplicates, and the closed one now has a fix attached.

Your **decision point**: while fixing it, you notice the same loop pattern in another method. Do you fix it in the same pull request, or open a separate ticket? You open **BOOK-215**. A pull request that fixes one ticket stays easy to review and easy to revert, and the second problem doesn't get lost. It's written down with a number.

When the pull request merges, the ticket moves to **Done**, and the history reads like a story: problem, discussion, fix, who did it.

## Formal detail

A **ticket** (also called an **issue**, **task**, **work item** or **story**, depending on the tool) is a tracked record of one piece of work. The usual fields:

|Field|Purpose|
|---|---|
|**ID / key** (`BOOK-212`)|Unique number, used in branches, commits and conversations|
|**Title**|One-line summary|
|**Description**|What's wrong or needed, plus steps to reproduce for bugs|
|**Type**|Bug, feature, task, or sometimes "epic" (a big feature made of many tickets)|
|**Status**|Where it is in the workflow: To Do, In Progress, In Review, Done|
|**Assignee**|Who's responsible|
|**Priority**|How urgent it is|
|**Comments / links**|Discussion, logs, screenshots, links to related tickets and pull requests|

The tools that hold tickets are **Jira**, **GitHub Issues**, **GitLab Issues**, **Linear** and **Trello**. The key is the form of the ID: Jira uses `PROJECT-NUMBER` (`BOOK-212`), and GitHub uses `#212`.

## Why teams use them

- **A written record.** The reason for a change lives next to the change, so someone reading the code a year later can find out why.
- **Traceability.** Commit, branch and pull request all carry the ticket number, so you can go from a line of code to the request behind it.
- **Shared visibility.** Everyone sees what's being worked on, which prevents two people fixing the same bug.
- **Priorities.** The team can order the work, instead of whoever asks loudest.

## Where this connects to your own projects

You don't need a company to use tickets. Even on a solo project, such as your Spring Boot practice apps, a **GitHub Issues** list works the same way. Write `#1 Add login endpoint`, make a branch `1-add-login`, and commit with `Fixes #1`. GitHub then closes the issue automatically when that commit reaches `main`. It's a good habit to build early, because every team job uses it.

## Definitions

- **Ticket / issue:** a tracked unit of work with a unique ID.
- **Board:** the view that groups tickets into status columns (often called a Kanban board).
- **Workflow:** the allowed path of statuses a ticket moves through.
- **Pull request (PR):** a request to merge your branch into another, usually `main`, which teammates review.
- **Epic:** a large goal broken into many tickets.
- **Backlog:** the list of tickets not yet started.

## Quick recap

- A ticket is a numbered, written unit of work that moves through statuses until it's done.
- The ticket number appears in your branch name, commit messages and pull request, so everything links back to it.
- It gives the team a shared record of what was asked, who did it, and why.
- You can practice the same workflow alone with GitHub Issues.




[[Computer & Programming]]