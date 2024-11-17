# Falinks

Generate geometry data of administrative regions from OpenStreetMap.

## At a Glance

Falink is a command line tool to:
1. Fetch countries ([ISO 3166-1 code](https://en.wikipedia.org/wiki/ISO_3166-1) registered) and their subdivisions ([ISO 3166-2 code](https://en.wikipedia.org/wiki/ISO_3166-2) registered) from OpenStreetMap
2. Fetch boundaries and coastlines of regions from OpenStreetMap to build geometries (multi-polygons) of land
3. Generate [S2 Cell](http://s2geometry.io/devguide/s2cell_hierarchy) cover of the geometries
4. Generate index files with hierarchy, area and bounding box of regions, and level-5 cell index of the covers
4. Fetch data of regions from [Wikidata](https://www.wikidata.org), download flag images and generate [Xcode string catalog](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)

The geometries and covers are generated for subdivisions and countries without subdivision, countries with subdivisions will be skipped.

Let's call `ISO 3166-1` region as `country` and `ISO 3166-2` regions as `subdivision` to save some bytes.

### Targets

- The [`Command`](./Sources/Command/) provides the command line interface
- The [`Generator`](./Sources/Generator/) provides features
- The [`Coverer`](./Sources/Coverer/) provides a very rough implementation of S2RegionCoverer of S2Geometry
- The [`OverpassKit`](./Sources/OverpassKit/) provides an Swift interface of [Overpass API](https://wiki.openstreetmap.org/wiki/Overpass_API) and `@resultBuilder`s to create Queries in Swift way

## Usage

```shell
$ swift run falinks <subcommand> -d <work-directory> [options...]
```

Since Falinks queries data from OSM which is built by contributors from all around the world, it's highly recommended to run the commands by steps and always check the result manually.
If data-related error occurs or the result is incorrect, please try to contribute a fix to OSM.

### Fetch Metadata

```shell
$ swift run falinks metadata -d <work-directory> [options...]
```

Falink quries relations of countries and their subdivisions with Overpass API to build metadata for all the following steps.

The list of countries without subdivisions are [hard-coded](./Sources/Generator/Generator+Metadata.swift).

### Fetch and Build Geometries

```shell
$ swift run falinks geometry -d <work-directory> [options...]
```

Falink quries boundaries and coastlines of each region with Overpass, and connect each segment to build `Ring`s of `Polygon`s.

For OSM, boundaries of one region should be close to represent the region, the region may contains sea part (in which the boundaries are tagged with `maritime=yes`). Similarily, coastlines should alse be close to represent the land and sea.
Since Falinks generates geometry of the land part of regions, we need to fetch both land boundaries and coastlines in its region.
However, boundaries and coastlines are not guaranteed to be connected to each other, therefore it's recommended to generate one geometry each time, and it may be necessary to omit some segments manually with option `--omit-segments <id...>`.

### Generate Covers

```shell
$ swift run falinks geometry -d <work-directory> [options...]
```

Falinks generates covers for each region from the geometries built in previous step.

The covering algorithm is very rough and the efficiency is really awful, it may take hours or even days to generate covers for one big region.
It's recommended to reduce the cell level with option `--level` and limit the concurrent task with option `--tasks` to prevent CPU being totally consumed.

To prevent system falling asleep, use `caffeinate` command:

```shell
$ caffeinate -is swift run falinks geometry -d <work-directory> [options...]
```

### Generate Indecies

```shell
$ swift run falinks index -d <work-directory> [options...]
```

Falinks generates two JSON files:
- `regions.json` contains hierarchy of the countries and their subdivisions, with their area and bounding boxes
- `cells.json` contains level 5 cells to regions index of all covers

### Fetch Wikidata

```shell
$ swift run falinks wikidata -d <work-directory> [options...]
```

Falinks will download the entry JSON of each region. For entry containing flag image data, Falinks will also download the image.

At last, Falinks will extract the labels (localizations) from entries to create / update Xcode string catalog.

## Platform Availability

One of the dependency, `SphereGeometry` depends on the `simd` module of Apple platform, therefore it's not available on Windows or Linux yet.
