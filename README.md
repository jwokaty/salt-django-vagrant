# Salt Django Vagrant 

A salted Django development Vagrant using

* Vagrant
* Django
* Saltstack
* Mariadb
* Virtualenv
* Apache
* Supervisor
* Gunicorn

The website can be seen at 0.0.0.0:8080.

## Requirements

This project requires

* [Vagrant](https://vagrantup.com)
* [Virtualbox](https://virtualbox.org)

## Set Up

    git clone https://github.com/jwokaty/salt-django-vagrant.git
    cd salt-django-vagrant

If desired, make changes to the the project pillar at
salt-django-vagrant/salt/pillar/project/init.sls. To start the environment,

    vagrant up

## Restarting Gunicorn

After halting the vagrant, you'll need to restart gunicorn.

    sudo supervisorctl restart gunicorn

## Using Django's Built-in Server Rather than Gunicorn

If you don't want to use Apache, Supervisor, and Gunicorn, you can use Django's
built in server:

    sudo service supervisor stop
    source venv/bin/activate
    python manage.py runserver 0.0.0.0:8000
