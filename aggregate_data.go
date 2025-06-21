package main

import (
	"encoding/csv"
	"fmt"
	"log"
	"math"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/xuri/excelize/v2"
)

// CPUData represents a single CPU measurement
type CPUData struct {
	RunNumber   int
	Cycles      int64
	CPUClockHz  int64
	Algorithm   string
	File        string
	FileSizeBytes int
}

// MemoryData represents a single memory allocation/free event
type MemoryData struct {
	Alignment        string
	AllocationType   string
	AllocationSizeBytes int64
	Algorithm        string
	File             string
	FileSizeBytes    int
}

// CPUStats holds aggregated statistics for CPU data
type CPUStats struct {
	Algorithm   string
	File        string
	FileSizeBytes int
	Average     float64
	StdDev      float64
	Min         int64
	Max         int64
	Count       int
}

// MemoryStats holds aggregated statistics for memory data
type MemoryStats struct {
	Algorithm           string
	File                string
	FileSizeBytes       int
	TotalAllocated      int64
	TotalFreed          int64
	AverageMemoryUsage  float64
	AllocationCount     int
	FreeCount           int
}

func main() {
	// Create Excel file
	f := excelize.NewFile()
	defer func() {
		if err := f.Close(); err != nil {
			log.Println(err)
		}
	}()

	// Process CPU data
	cpuStats, err := processCPUData("results/sort/cpu")
	if err != nil {
		log.Fatalf("Error processing CPU data: %v", err)
	}
	
	if err := writeCPUSheet(f, cpuStats); err != nil {
		log.Fatalf("Error writing CPU sheet: %v", err)
	}

	// Process Memory data
	memoryStats, err := processMemoryData("results/sort/memory")
	if err != nil {
		log.Fatalf("Error processing memory data: %v", err)
	}
	
	if err := writeMemorySheet(f, memoryStats); err != nil {
		log.Fatalf("Error writing memory sheet: %v", err)
	}

	// Save the file
	if err := f.SaveAs("aggregate_data.xlsx"); err != nil {
		log.Fatal(err)
	}

	fmt.Println("Excel file 'aggregate_data.xlsx' created successfully!")
}

func processCPUData(cpuDir string) ([]CPUStats, error) {
	var allStats []CPUStats
	algorithmFileMap := make(map[string][]CPUData)

	// Read all CPU CSV files
	files, err := filepath.Glob(filepath.Join(cpuDir, "*.csv"))
	if err != nil {
		return nil, fmt.Errorf("error globbing CPU files: %w", err)
	}

	for _, file := range files {
		records, err := readCSV(file)
		if err != nil {
			log.Printf("Error reading %s: %v", file, err)
			continue
		}

		// Skip header
		for i := 1; i < len(records); i++ {
			record := records[i]
			if len(record) < 6 {
				log.Printf("Warning: skipping malformed record in %s at line %d", file, i+1)
				continue
			}

			runNumber, err := strconv.Atoi(record[0])
			if err != nil {
				log.Printf("Warning: invalid run number in %s at line %d: %v", file, i+1, err)
				continue
			}
			
			cycles, err := strconv.ParseInt(record[1], 10, 64)
			if err != nil {
				log.Printf("Warning: invalid cycles in %s at line %d: %v", file, i+1, err)
				continue
			}
			
			cpuClockHz, err := strconv.ParseInt(record[2], 10, 64)
			if err != nil {
				log.Printf("Warning: invalid CPU clock Hz in %s at line %d: %v", file, i+1, err)
				continue
			}
			
			algorithm := record[3]
			file := record[4]
			
			fileSizeBytes, err := strconv.Atoi(record[5])
			if err != nil {
				log.Printf("Warning: invalid file size bytes in %s at line %d: %v", file, i+1, err)
				continue
			}

			key := fmt.Sprintf("%s_%s", algorithm, file)
			algorithmFileMap[key] = append(algorithmFileMap[key], CPUData{
				RunNumber:     runNumber,
				Cycles:        cycles,
				CPUClockHz:    cpuClockHz,
				Algorithm:     algorithm,
				File:          file,
				FileSizeBytes: fileSizeBytes,
			})
		}
	}

	// Calculate statistics for each algorithm-file combination
	for key, data := range algorithmFileMap {
		if len(data) == 0 {
			continue
		}

		parts := strings.Split(key, "_")
		if len(parts) < 2 {
			log.Printf("Warning: invalid key format: %s", key)
			continue
		}

		algorithm := parts[0]
		file := strings.Join(parts[1:], "_")

		stats := calculateCPUStats(data, algorithm, file)
		allStats = append(allStats, stats)
	}

	return allStats, nil
}

func processMemoryData(memoryDir string) ([]MemoryStats, error) {
	var allStats []MemoryStats
	algorithmFileMap := make(map[string][]MemoryData)

	// Read all memory CSV files
	files, err := filepath.Glob(filepath.Join(memoryDir, "*.csv"))
	if err != nil {
		return nil, fmt.Errorf("error globbing memory files: %w", err)
	}

	for _, file := range files {
		records, err := readCSV(file)
		if err != nil {
			log.Printf("Error reading %s: %v", file, err)
			continue
		}

		// Skip header
		for i := 1; i < len(records); i++ {
			record := records[i]
			if len(record) < 6 {
				log.Printf("Warning: skipping malformed record in %s at line %d", file, i+1)
				continue
			}

			alignment := record[0]
			allocationType := record[1]
			
			allocationSizeBytes, err := strconv.ParseInt(record[2], 10, 64)
			if err != nil {
				log.Printf("Warning: invalid allocation size bytes in %s at line %d: %v", file, i+1, err)
				continue
			}
			
			algorithm := record[3]
			file := record[4]
			
			fileSizeBytes, err := strconv.Atoi(record[5])
			if err != nil {
				log.Printf("Warning: invalid file size bytes in %s at line %d: %v", file, i+1, err)
				continue
			}

			key := fmt.Sprintf("%s_%s", algorithm, file)
			algorithmFileMap[key] = append(algorithmFileMap[key], MemoryData{
				Alignment:           alignment,
				AllocationType:      allocationType,
				AllocationSizeBytes: allocationSizeBytes,
				Algorithm:           algorithm,
				File:                file,
				FileSizeBytes:       fileSizeBytes,
			})
		}
	}

	// Calculate statistics for each algorithm-file combination
	for key, data := range algorithmFileMap {
		if len(data) == 0 {
			continue
		}

		parts := strings.Split(key, "_")
		if len(parts) < 2 {
			log.Printf("Warning: invalid key format: %s", key)
			continue
		}

		algorithm := parts[0]
		file := strings.Join(parts[1:], "_")

		stats := calculateMemoryStats(data, algorithm, file)
		allStats = append(allStats, stats)
	}

	return allStats, nil
}

func calculateCPUStats(data []CPUData, algorithm, file string) CPUStats {
	if len(data) == 0 {
		return CPUStats{Algorithm: algorithm, File: file}
	}

	var sum int64
	var min, max int64 = data[0].Cycles, data[0].Cycles
	fileSizeBytes := data[0].FileSizeBytes

	for _, d := range data {
		sum += d.Cycles
		if d.Cycles < min {
			min = d.Cycles
		}
		if d.Cycles > max {
			max = d.Cycles
		}
	}

	average := float64(sum) / float64(len(data))

	// Calculate standard deviation
	var varianceSum float64
	for _, d := range data {
		diff := float64(d.Cycles) - average
		varianceSum += diff * diff
	}
	stdDev := math.Sqrt(varianceSum / float64(len(data)))

	return CPUStats{
		Algorithm:     algorithm,
		File:          file,
		FileSizeBytes: fileSizeBytes,
		Average:       average,
		StdDev:        stdDev,
		Min:           min,
		Max:           max,
		Count:         len(data),
	}
}

func calculateMemoryStats(data []MemoryData, algorithm, file string) MemoryStats {
	if len(data) == 0 {
		return MemoryStats{Algorithm: algorithm, File: file}
	}

	var totalAllocated, totalFreed int64
	var allocationCount, freeCount int
	fileSizeBytes := data[0].FileSizeBytes

	// Track current memory usage for average calculation
	var currentMemory int64
	var memorySamples []int64

	for _, d := range data {
		if d.AllocationType == "ALLOC" {
			totalAllocated += d.AllocationSizeBytes
			allocationCount++
			currentMemory += d.AllocationSizeBytes
		} else if d.AllocationType == "FREE" {
			totalFreed += d.AllocationSizeBytes
			freeCount++
			currentMemory -= d.AllocationSizeBytes
			if currentMemory < 0 {
				currentMemory = 0 // Can't have negative memory
			}
		}
		memorySamples = append(memorySamples, currentMemory)
	}

	// Calculate average memory usage
	var totalMemory int64
	for _, mem := range memorySamples {
		totalMemory += mem
	}
	averageMemoryUsage := float64(0)
	if len(memorySamples) > 0 {
		averageMemoryUsage = float64(totalMemory) / float64(len(memorySamples))
	}

	return MemoryStats{
		Algorithm:          algorithm,
		File:               file,
		FileSizeBytes:      fileSizeBytes,
		TotalAllocated:     totalAllocated,
		TotalFreed:         totalFreed,
		AverageMemoryUsage: averageMemoryUsage,
		AllocationCount:    allocationCount,
		FreeCount:          freeCount,
	}
}

func writeCPUSheet(f *excelize.File, stats []CPUStats) error {
	// Create CPU sheet
	sheetName := "CPU Statistics"
	_, err := f.NewSheet(sheetName)
	if err != nil {
		return fmt.Errorf("error creating CPU sheet: %w", err)
	}

	// Write headers
	headers := []string{"Algorithm", "File", "File Size (bytes)", "Average Cycles", "Std Dev", "Min Cycles", "Max Cycles", "Sample Count"}
	for i, header := range headers {
		cell := fmt.Sprintf("%c1", 'A'+i)
		if err := f.SetCellValue(sheetName, cell, header); err != nil {
			return fmt.Errorf("error setting header %s: %w", header, err)
		}
	}

	// Write data
	for i, stat := range stats {
		row := i + 2
		if err := f.SetCellValue(sheetName, fmt.Sprintf("A%d", row), stat.Algorithm); err != nil {
			return fmt.Errorf("error setting algorithm for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("B%d", row), stat.File); err != nil {
			return fmt.Errorf("error setting file for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("C%d", row), stat.FileSizeBytes); err != nil {
			return fmt.Errorf("error setting file size for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("D%d", row), stat.Average); err != nil {
			return fmt.Errorf("error setting average for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("E%d", row), stat.StdDev); err != nil {
			return fmt.Errorf("error setting std dev for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("F%d", row), stat.Min); err != nil {
			return fmt.Errorf("error setting min for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("G%d", row), stat.Max); err != nil {
			return fmt.Errorf("error setting max for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("H%d", row), stat.Count); err != nil {
			return fmt.Errorf("error setting count for row %d: %w", row, err)
		}
	}

	// Auto-size columns
	for i := 0; i < len(headers); i++ {
		col := string(rune('A' + i))
		if err := f.SetColWidth(sheetName, col, col, 15); err != nil {
			return fmt.Errorf("error setting column width for %s: %w", col, err)
		}
	}

	return nil
}

func writeMemorySheet(f *excelize.File, stats []MemoryStats) error {
	// Create Memory sheet
	sheetName := "Memory Statistics"
	_, err := f.NewSheet(sheetName)
	if err != nil {
		return fmt.Errorf("error creating memory sheet: %w", err)
	}

	// Write headers
	headers := []string{"Algorithm", "File", "File Size (bytes)", "Total Allocated (bytes)", "Total Freed (bytes)", "Average Memory Usage (bytes)", "Allocation Count", "Free Count"}
	for i, header := range headers {
		cell := fmt.Sprintf("%c1", 'A'+i)
		if err := f.SetCellValue(sheetName, cell, header); err != nil {
			return fmt.Errorf("error setting header %s: %w", header, err)
		}
	}

	// Write data
	for i, stat := range stats {
		row := i + 2
		if err := f.SetCellValue(sheetName, fmt.Sprintf("A%d", row), stat.Algorithm); err != nil {
			return fmt.Errorf("error setting algorithm for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("B%d", row), stat.File); err != nil {
			return fmt.Errorf("error setting file for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("C%d", row), stat.FileSizeBytes); err != nil {
			return fmt.Errorf("error setting file size for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("D%d", row), stat.TotalAllocated); err != nil {
			return fmt.Errorf("error setting total allocated for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("E%d", row), stat.TotalFreed); err != nil {
			return fmt.Errorf("error setting total freed for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("F%d", row), stat.AverageMemoryUsage); err != nil {
			return fmt.Errorf("error setting average memory usage for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("G%d", row), stat.AllocationCount); err != nil {
			return fmt.Errorf("error setting allocation count for row %d: %w", row, err)
		}
		if err := f.SetCellValue(sheetName, fmt.Sprintf("H%d", row), stat.FreeCount); err != nil {
			return fmt.Errorf("error setting free count for row %d: %w", row, err)
		}
	}

	// Auto-size columns
	for i := 0; i < len(headers); i++ {
		col := string(rune('A' + i))
		if err := f.SetColWidth(sheetName, col, col, 20); err != nil {
			return fmt.Errorf("error setting column width for %s: %w", col, err)
		}
	}

	return nil
}

func readCSV(filename string) ([][]string, error) {
	file, err := os.Open(filename)
	if err != nil {
		return nil, fmt.Errorf("error opening file %s: %w", filename, err)
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("error reading CSV from %s: %w", filename, err)
	}
	
	return records, nil
} 