Attribute VB_Name = "Module4"
Function SimilarityCosine(s1 As String, s2 As String) As Double
    Dim words1 As Object
    Set words1 = CreateObject("Scripting.Dictionary")
    
    Dim words2 As Object
    Set words2 = CreateObject("Scripting.Dictionary")
    
    Dim i As Integer
    Dim j As Integer
    Dim dotProduct As Double
    Dim magnitude1 As Double
    Dim magnitude2 As Double
    
    ' Split the strings into words and create vectors
    Dim words As Variant
    words = Split(s1 & " " & s2, " ")
    
    For i = LBound(words) To UBound(words)
        If Trim(words(i)) <> "" Then
            words1(Trim(words(i))) = 0
            words2(Trim(words(i))) = 0
        End If
    Next i
    
    ' Populate the vectors
    For i = LBound(words) To UBound(words)
        If Trim(words(i)) <> "" Then
            If i <= UBound(Split(s1, " ")) Then
                words1(Trim(words(i))) = words1(Trim(words(i))) + 1
            Else
                words2(Trim(words(i))) = words2(Trim(words(i))) + 1
            End If
        End If
    Next i
    
    ' Calculate dot product and magnitudes
    For Each Key In words1.Keys
        dotProduct = dotProduct + (words1(Key) * words2(Key))
        magnitude1 = magnitude1 + (words1(Key) * words1(Key))
        magnitude2 = magnitude2 + (words2(Key) * words2(Key))
    Next Key
    
    ' Calculate cosine similarity
    If magnitude1 * magnitude2 = 0 Then
        SimilarityCosine = 0
    Else
        SimilarityCosine = dotProduct / (Sqr(magnitude1) * Sqr(magnitude2))
    End If
End Function
