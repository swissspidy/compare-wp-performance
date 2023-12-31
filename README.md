# compare-wp-performance

Easily compare performance between two WordPress core releases with benchmarking.

Based on [this document](https://docs.google.com/document/d/1aionUJ9N35WWk3CwY5mfepRzf3psrJ0HJhw4B2Bsp_0/edit)
and the [handbook entry on benchmarking WordPress PHP performance](https://make.wordpress.org/performance/handbook/measuring-performance/benchmarking-php-performance-with-server-timing/#preparing-a-wordpress-site-for-server-timing-benchmarks),
this repository provides a [GitHub Action](https://github.com/features/actions) to automate this process.

## Usage

### Manually

Run the following command in the terminal:

```shell
./run.sh [old=latest] [new=trunk] [skip_init=false] [output=markdown] [skip_formatting=false] [print_to_files=false]
```

By default, it compares the latest stable release with the current trunk version. So `./run.sh` is the same as `./run.sh latest trunk`.

You can choose different versions of course. For example, to compare with the current RC:

```shell
./run.sh latest 6.3-branch
```

To skip the initialization steps when you want to run the benchmarks multiple times after another:

```shell
./run.sh latest trunk true
```

To test a specific WP version by ZIP file:

```shell
./run.sh latest https://wordpress.org/wordpress-6.3-RC2.zip
```

The default output is as Markdown tables. To get output data as CSV without formatted numbers:

```shell
./run.sh latest trunk false csv true
```

To pipe that output into (CSV) files:

```shell
./run.sh latest trunk false csv true true
```

This will result in four CSV files with the individual table results.

### GitHub Actions

This repository provides a GitHub Action to compare benchmarks of two separate WordPress versions.

The results are posted as a [job summary](https://github.blog/2022-05-09-supercharging-github-actions-with-job-summaries/).

By default, it compares the latest stable release with the current trunk version. You can choose different versions of course.

![Screenshot of the GitHub Actions UI to run the benchmark workflow](https://github.com/swissspidy/compare-wp-performance/assets/841956/b5cb4d93-6e51-458a-b25b-16bc17be8b3a)

**Note:** if you do not have access to run GitHub Action in this repository, you can fork it.
