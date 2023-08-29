# rabbitmq pull messages
This utility collects messages from rabbitmq with the support of rabbitmq admin.
The particularity of the following use case was that i had to modify the content of a grabbed messages
formatted in a certain way, so i wrote this utility to automate this step and automatically
get the message from a specific queue and pubblish it after the content was correctly parsed in the accepted format
to the other queue. The main reason of having the mentioned solution was that a legacy application
was writing custom messages to a rabbitmq instance, a new system was in place which had to slowly replace the legacy one.
The actual load on that specific queue was not that high allowing to use the following solution as a hack,
 waiting for the new system using celery tasks and rabbitmq to completely replace the legacy one.
I realize the mentioned use case was very specific, but it actually solved tons of issues and though to include this specific
utility in the repo
