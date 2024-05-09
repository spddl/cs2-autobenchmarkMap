# CS2 Auto BenchmarkMap

[![Downloads][1]][2] [![GitHub stars][3]][4]

[1]: https://img.shields.io/github/downloads/spddl/cs2-autobenchmarkMap/total.svg
[2]: https://github.com/spddl/cs2-autobenchmarkMap/releases "Downloads"
[3]: https://img.shields.io/github/stars/spddl/cs2-autobenchmarkMap.svg
[4]: https://github.com/spddl/cs2-autobenchmarkMap/stargazers "GitHub stars"

This tool serves as a convenient wrapper for initiating the CounterStrike 2 [Benchmark Map](https://steamcommunity.com/sharedfiles/filedetails/?id=3240880604) by [Angel](https://steamcommunity.com/id/AnnGell88/) and recording the [PresentMon](https://github.com/GameTechDev/PresentMon) data. Before using the tool, ensure that Angel's Workshop Map [CS2 Benchmark Map](https://steamcommunity.com/sharedfiles/filedetails/?id=3240880604) has been subscribed to.

## Usage

```ps
./benchmark.exe -name mybenchmark
```

### Options

- `-name string`: Set a custom filename for the output (default is current time: 020106150405).
- `-parameter string`: Specify CS2 parameters as a comma-separated list.
- `-secure`: Starts CS2 with Valve Anti-Cheat-System (VAC)

## Recording and Analysis

Once initiated, the tool will launch the CS2 Benchmark Map automatically. PresentMon will record the frame time data during the benchmarking process. After completion, the recorded data can be analyzed and compared using the [Frame Time Analysis](https://boringboredom.github.io/Frame-Time-Analysis/) tool by [Bored](https://github.com/BoringBoredom) on their website.

## Why Use This Tool?

Benchmarking scripts provide standardized performance tests and comparisons. By automating the process and providing easy access to tools such as PresentMon, users can efficiently evaluate and compare performance metrics.

Feel free to contribute to this project and improve its functionality!

## Testing and Optimization

This tool allows you to experiment with various settings and configurations to optimize performance. Here are some examples of what you can do:

- See how different Counter-Strike 2 launch settings like "High", "Vulkan", and "Threads X" affect your game.
- Experiment with CVars or different configurations in "video.txt" and compare their effects.
- Adjust Windows settings and test their impact. You just need to know how to set them using PowerShell.

### Cool Ideas to Try:

- Is it better to turn Windows GameMode On or Off when playing games?
- What about Windows Hardware accelerated GPU scheduling (On/Off)?
- Which is better for CS2: parameter threads set to 8 or 24?
- Explore MSI Mode of the GPU (GPU interrupts to specific CPU core(s))? [Check out GoInterruptPolicy](https://github.com/spddl/GoInterruptPolicy)
- Create custom Nvidia profiles using nvidiaProfileInspector and test individual settings.
- Experiment with different power plans.
