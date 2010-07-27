`sshag`
=======

This is a sourceable shell include file which provides a way to conveniently hook up with an operating ssh-agent.

Usage:

    $ ssh alotta@fagina.example.com
    Enter passphrase for key '/home/austin/.ssh/id_dsa': ^C
    $ source sshag.sh
    $ sshag
    Found ssh-agent /tmp/ssh-b0bs1edded/agent.12946
    2048 0d:db:a1:1a:cc:01:ad:ec:ab:00:d1:ed:eb:ac:1e:00 /home/austin/.ssh/id_dsa (DSA)
    $ ssh alotta@fagina.example.com
    ...

You might want to source it and run it from within your `~/.bashrc` file or other profile script.

It will start a new agent session if it doesn't find an agent to connect with.

## Licensing

This code was posted as a [response] to a question on superuser.com.
As I understand it, code posted to that site is under the terms of the
Creative Commons Attribution-Sharealike License,
so I'm attributing it to the superuser.com user [Zed].
SU currently links to [version 2.5] of the license.

A copy of [the full license] is distributed herein in the file COPYING.

### The basic gist of the license

#### You are free:

-   **to Share** — to copy, distribute and transmit the work
-   **to Remix** — to adapt the work

#### Under the following conditions:

-   **Attribution** — You must attribute the work in the manner
    specified by the author or licensor (but not in any way that
    suggests that they endorse you or your use of the work).
-   **Share Alike** — If you alter, transform, or build upon this
    work, you may distribute the resulting work only under the same or
    similar license to this one.


#### With the understanding that:

-   **Waiver** — Any of the above conditions can be [waived]
    if you get permission from the copyright holder.
-   **Public Domain** — Where the work or any of its elements
    is in the [public domain] under applicable law,
    that status is in no way affected by the license.
-   **Other Rights** — In no way are any of the following rights
    affected by the license:
    -   Your fair dealing or [fair use] rights,
        or other applicable copyright exceptions and limitations;
    -   The author's [moral] rights;
    -   Rights other persons may have either in the work itself
        or in how the work is used, such as [publicity] or privacy rights.

-   **Notice** — For any reuse or distribution, you must make clear
    to others the license terms of this work. The best way to do this
    is with a link to this web page.

[response]: http://superuser.com/questions/141044/sharing-the-same-ssh-agent-among-multiple-login-sessions#answer-141241
[Zed]: http://superuser.com/users/33648/zed
[version 2.5]: http://creativecommons.org/licenses/by-sa/2.5/
[the full license]: http://creativecommons.org/licenses/by-sa/2.5/legalcode
[waived]: http://wiki.creativecommons.org/Frequently_Asked_Questions#Can_I_change_the_terms_of_a_CC_license_or_waive_some_of_its_conditions.3F
[public domain]: http://wiki.creativecommons.org/Public_domain
[fair use]: http://wiki.creativecommons.org/Frequently_Asked_Questions#Do_Creative_Commons_licenses_affect_fair_use.2C_fair_dealing_or_other_exceptions_to_copyright.3F
[moral]: http://wiki.creativecommons.org/Frequently_Asked_Questions#I_don.E2.80.99t_like_the_way_a_person_has_used_my_work_in_a_derivative_work_or_included_it_in_a_collective_work.3B_what_can_I_do.3F
[publicity]: http://wiki.creativecommons.org/Frequently_Asked_Questions#When_are_publicity_rights_relevant.3F
