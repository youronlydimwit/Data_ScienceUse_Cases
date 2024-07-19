def data_desc_graph(df):
    try:
        # Check if necessary libraries are already imported
        import pandas as pd
        import matplotlib.pyplot as plt
        import math
    except ImportError:
        # If any library is not imported, load the necessary libraries
        import pandas as pd
        import matplotlib.pyplot as plt
        import math
        return "Libraries loaded"
    
    num_columns = df.shape[1]

    if num_columns % 3 == 0:
        num_rows = num_columns // 3
    else:
        num_rows = math.ceil(num_columns / 3)

    fig, axes = plt.subplots(num_rows, 3, figsize=(15, 5 * num_rows))
    axes = axes.flatten()

    for i, column in enumerate(df.columns):
        ax = axes[i]
        if pd.api.types.is_numeric_dtype(df[column]):
            # If the dtype is numeric, show a histogram
            df[column].plot(kind='hist', ax=ax, color='skyblue', edgecolor='black')
            ax.set_title(f'Histogram for {column}')
            ax.set_xlabel(column)
            ax.set_ylabel('Frequency')
        else:
            # If the dtype is not numeric, show a bar chart
            value_counts = df[column].value_counts()
            value_counts.plot(kind='bar', ax=ax, rot=45, color='skyblue', edgecolor='black')
            ax.set_title(f'Bar Chart for {column}')
            ax.set_xlabel(column)
            ax.set_ylabel('Count')

    fig.suptitle('This script produces Histogram for Numerical Data, Bar Charts for Categorical Data', fontsize=16)
    plt.tight_layout(rect=[0, 0, 1, 0.96])  # Adjust the layout for the main title
    plt.show()
    
    return "Dependencies Satisfied"
