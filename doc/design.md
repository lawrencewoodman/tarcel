Design Notes for Tarcel
=======================

Here are a few notes that explain some of the design decisions for Tarcel.

Philosophy
----------
_Tarcel_ is designed so that the _tarcel_'s should be independent of _Tarcel_ and shouldn't have to keep being re-packaged under newer versions of _Tarcel_.  This is why `::tarcel::commands` exist, so rather than _Tarcel_ interrogating the _tarcel_ for information, `::tarcel::commands::info` is called which will return the information as a dictionary.  This will make it easier to preserve future compatibility.

Just enough functionality has been implemented for the uses that it has been put to so far.  If further needs present themselves then functionality will be extended based on those needs.

_tarcel_ Format
---------------
A _tarcel_ consists of some header code and a tarball separated by a `CTRL-Z`.  This tarball is a start-up tarball which contains the code to take over the function of commands such as `source`, `open`, `load`, etc, to read files in the _tarcel_ as if they were on the native filesystem.  The files that have been packaged into the _tarcel_ are kept in a further tarball.  The tarballs are Unix v7 style tarballs for simplicity.

