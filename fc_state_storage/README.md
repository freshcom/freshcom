# Freshcom State Storage

Freshcom State Storage provides a storage for storing persistent state, it comes with a memory adapter and a Dynamo DB adapter. It also provides a few globally available state store for all services of the Freshcom Project.

The state stored in state storage are just key value pairs as the state is only used for the command side of the full CQRS pattern, for example checking whether username is unique or not.

Read side project should never be store in the state storage.
