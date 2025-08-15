# Filmvision

This is a Phoenix application that serves as a base for some apps.

The name is filmvision because I started a project with this name and decided to leave the base here, and it is quite annoying to have some generators/ignite/cookiecutter for it, so I'll leve as sample code.

What we have is a bare phoenix application with some extras:
I used the `phx.gen.auth` generator and added organizations and projects as part of the scope.

Also replaced daisyui with basecoat and built some layouts:

- site: marketing site
- auth: for authentication views
- app: a sidebar/offcanvas for the authed user.

## Next steps
- configure google log in
- configure email
- production release
- where to put the organization/project entrypoint for crud
- background jobs
