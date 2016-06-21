Usage
=====

Installing
----------

Installation is quite simple and can be done via pip::

    pip install django-afip

Do keep in mind that requirements.txt points to a fork of ``suds-py``, since
upstream is broken and *will fail*.

You'll then need to configure your project to use it by adding it to
settings.py::

    INSTALLED_APPS = (
        ...
        'django_afip',
        ...
    )

Make sure to run all migrations after you've added the app (eg: ``python
manage.py migrate``).

Getting started
---------------

First of all, you'll need to create a :class:`~.TaxPayer`
instance, and upload the related SSL key and certificate (for authorization).

django-afip includes admin views for every model included, and it's the
recommended way to create :class:`~.TaxPayer` objects.

Once you have created a :class:`~.TaxPayer`, you'll need its points of sales. This,
again, can be done via the admin by selecting "fetch points of sales'. You may
also do this programmatically via :meth:`~.TaxPayer.fetch_points_of_sales`.

Metadata populuation
~~~~~~~~~~~~~~~~~~~~

You'll also need to pre-populate certain models with AFIP-defined metadata
(:class:`~.ReceiptType`, :class:`~.DocumentType` and a few others).

Rather than include fixtures which require updating over time, we fetch this
information from AFIP's web services via an included django management command.
This command is idempotent, and running it more than once will not create any
duplicate data. To fetch all metadata, simply run::

    python manage.py afipmetadata

This metadata can also be downloaded programmatically, via
:func:`.models.populate_all`.

You are now ready to start creating and validating receipts. While you may do
this via the admin as well, you probably want to do this programmatically or via
some custom view.

Example
~~~~~~~

This brief example shows how to achieve the above::

    from django.core.files import File
    from django_afip import models

    # Create a TaxPayer object:
    taxpayer = models.TaxPayer(
        pk=1,
        name='test taxpayer',
        cuit=20329642330,
        is_sandboxed=True,
    )

    # Add the key and certificate files to the TaxPayer:
    with open('/path/to/your.key') as key:
        taxpayer.key.save('test.key', File(key))
    with open('/path/to/your.crt') as crt:
        taxpayer.certificate.save('test.crt', File(crt))

    taxpayer.save()

    # Load all metadata:
    models.populate_all()

    # Get the TaxPayer's Point of Sales:
    taxpayer.fetch_points_of_sales()

PDF Receipts
------------

Version 1.2.0 introduced PDF-generation for validated receipts. These PDFs are
backed by the :class:`~.ReceiptPDF` model.

There are two ways of creating these objects; you can do this manually, or via
these steps:

* Creating a :class:`~.TaxPayerProfile` object for your :class:`~.TaxPayer`,
  with the right default values.
* Create the PDFs via ``ReceiptPDF.objects.create_for_receipt()``.
* Add the proper :class:`~.ReceiptEntry` objects to the :class:`~.Receipt`.
  Each :class:`~.ReceiptEntry` represents a line in the resulting PDF file.

The PDF file itself can then be generated via::

    # Save the file as a model field into your MEDIA_ROOT directory:
    receipt_pdf.save_pdf()
    # Save to some custom file-like-object:
    receipt_pdf.save_pdf_to(file_object)

The former is usually recommended since it allows simpler interaction via
standard django patterns.

Exposing receipts
~~~~~~~~~~~~~~~~~

Generated receipt files may be exposed both as PDF or html with an existing
view, for example, using::

    url(
        r'^invoices/pdf/(?P<pk>\d+)?$',
        views.ReceiptPDFView.as_view(),
        name='receipt_view',
    ),
    url(
        r'^invoices/html/(?P<pk>\d+)?$',
        views.ReceiptHTMLView.as_view(),
        name='receipt_view',
    ),

You'll generally want to subclass this view, and add some authorization checks
to it. If you want some other, more complex generation (like sending via
email), these views should serve as a reference to the PDF API.

The template used for the HTML and PDF receipts is found in
``templates/django_afip/invoice.html``. If you want to override the default (you
probably do), simply place a template with the same path/name inside your own
app, and make sure it's listed *before* ``django_afip`` in ``INSTALLED_APPS``.